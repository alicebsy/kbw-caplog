import Foundation
import Photos
import UIKit

@MainActor
final class ScreenshotMonitor: NSObject, PHPhotoLibraryChangeObserver {
    static let shared = ScreenshotMonitor()
    
    private let processingService = ScreenshotProcessingService()
    private let cardManager = CardManager.shared
    
    private var screenshotCollection: PHAssetCollection?
    private var lastProcessedAssetIdentifier: String?
    
    private override init() {
        super.init()
    }
    
    /// 스크린샷 앨범 찾기 (시뮬레이터에서는 .smartAlbumScreenshots가 비어 있을 수 있어 제목·최근 항목 fallback)
    static func findScreenshotCollection() -> PHAssetCollection? {
        let bySubtype = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )
        if let first = bySubtype.firstObject { return first }
        let all = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        var result: PHAssetCollection?
        all.enumerateObjects { col, _, stop in
            if col.localizedTitle == "Screenshots" || col.localizedTitle?.contains("스크린샷") == true {
                result = col
                stop.pointee = true
            }
        }
        if result != nil { return result }
        // 시뮬레이터 등에서 스크린샷 앨범이 없으면 최근 항목(Recents) 사용
        let recents = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: nil
        )
        return recents.firstObject
    }
    
    /// 모니터링 시작
    func startMonitoring() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        guard status == .authorized || status == .limited else {
            print("❌ ScreenshotMonitor: 사진 권한 없음")
            return
        }
        
        screenshotCollection = Self.findScreenshotCollection()
        if screenshotCollection == nil {
            print("⚠️ ScreenshotMonitor: 스크린샷 앨범을 찾지 못함 (시뮬레이터에서는 Cmd+S로 찍은 항목이 앨범에 들어갈 때까지 대기)")
        }
        
        PHPhotoLibrary.shared().register(self)
        print("✅ ScreenshotMonitor: 실시간 스크린샷 모니터링 시작")
    }
    
    /// 모니터링 중지
    func stopMonitoring() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        print("⏹️ ScreenshotMonitor: 모니터링 중지")
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // 콜백이 백그라운드 스레드에서 올 수 있으므로 MainActor에서 처리
        Task { @MainActor in
            if screenshotCollection == nil {
                screenshotCollection = Self.findScreenshotCollection()
            }
            guard let collection = screenshotCollection else { return }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let screenshots = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            
            guard let changeDetails = changeInstance.changeDetails(for: screenshots),
                  changeDetails.hasIncrementalChanges else {
                return
            }
            
            let insertedIndexes = changeDetails.insertedIndexes
            guard let insertedIndexes = insertedIndexes, !insertedIndexes.isEmpty else {
                return
            }
            
            print("📸 새 스크린샷 감지: \(insertedIndexes.count)개")
            
            for index in insertedIndexes {
                let asset = changeDetails.fetchResultAfterChanges.object(at: index) as! PHAsset
                if ScreenshotIndexer.shared.isAssetProcessed(asset) {
                    print("⏭️ 이미 카드로 만든 스크린샷 스킵: \(asset.localIdentifier)")
                    continue
                }
                if lastProcessedAssetIdentifier == asset.localIdentifier {
                    print("⏭️ 동일 세션에서 이미 처리한 스크린샷 스킵")
                    continue
                }
                lastProcessedAssetIdentifier = asset.localIdentifier
                processNewScreenshot(asset: asset)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func processNewScreenshot(asset: PHAsset) {
        print("🔍 스크린샷 처리 시작: \(asset.localIdentifier)")
        
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 1080, height: 1920)
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = false
        requestOptions.isNetworkAccessAllowed = true
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: requestOptions
        ) { [weak self] image, info in
            guard let self, let uiImage = image else {
                print("❌ 이미지 로드 실패")
                return
            }
            
            // 다운로드 중인 경우 스킵
            if let downloading = info?[PHImageResultIsDegradedKey] as? Bool, downloading {
                return
            }
            
            print("📤 GPT 파이프라인 실행 중...")
            
            self.processingService.processScreenshot(image: uiImage) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let processingResult):
                        let card = processingResult.card
                        print("📤 ScreenshotMonitor: OCR/GPT 결과 DB 저장 시도 - \(card.title)")
                        if let id = card.thumbnailURL ?? card.screenshotURLs.first {
                            CardImageStore.save(image: uiImage, id: id)
                        }
                        ScreenshotIndexer.shared.markAssetAsProcessed(asset)
                        await self.cardManager.createCard(card)
                        await self.uploadScreenshotToServer(image: uiImage)
                        self.showNotification(for: processingResult.card)
                    case .failure(let error):
                        print("❌ 자동 분류 실패: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// 스크린샷을 서버에 업로드 (POST /api/screenshots/upload) → DB 저장 후 마이페이지 목록에 반영
    private func uploadScreenshotToServer(image: UIImage) async {
        guard let userNo = try? await UserService().fetchMe().userNo else { return }
        let no = userNo
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ScreenshotUploader.upload(image: image, userId: no) { _ in
                continuation.resume()
            }
        }
    }

    /// 로컬 알림 표시 (선택사항)
    private func showNotification(for card: Card) {
        // UNUserNotificationCenter를 사용하여 알림 표시
        // 권한이 필요하므로 선택사항으로 구현
        print("🔔 알림: '\(card.title)' 카드가 생성되었습니다.")
    }
}
