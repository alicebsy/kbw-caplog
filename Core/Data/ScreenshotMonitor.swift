import Foundation
@preconcurrency import Photos
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
    
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Photos 콜백은 임의 스레드에서 오므로 MainActor 상태에 직접 접근하지 않습니다.
        Task { @MainActor [weak self] in
            self?.handlePhotoLibraryChange(changeInstance)
        }
    }

    private func handlePhotoLibraryChange(_ changeInstance: PHChange) {
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

        guard let insertedIndexes = changeDetails.insertedIndexes,
              !insertedIndexes.isEmpty else {
            return
        }

        print("📸 새 스크린샷 감지: \(insertedIndexes.count)개")

        for index in insertedIndexes {
            let asset = changeDetails.fetchResultAfterChanges.object(at: index)
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
    
    // MARK: - Private Methods
    
    private func processNewScreenshot(asset: PHAsset) {
        print("🔍 스크린샷 처리 시작: \(asset.localIdentifier)")
        
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 1080, height: 1920)
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = false
        // iCloud 다운로드 없이 기기에 원본이 있는 사진만 처리합니다.
        requestOptions.isNetworkAccessAllowed = false
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: requestOptions
        ) { [weak self] image, info in
            let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            guard !isDegraded else { return }

            let isCancelled = info?[PHImageCancelledKey] as? Bool ?? false
            let imageError = info?[PHImageErrorKey] as? Error
            guard let self, !isCancelled, imageError == nil, let uiImage = image else {
                let reason = imageError?.localizedDescription
                    ?? (isCancelled ? "사진 요청이 취소되었습니다." : "사진 데이터를 불러오지 못했습니다.")
                Task { @MainActor [weak self] in
                    if self?.lastProcessedAssetIdentifier == asset.localIdentifier {
                        self?.lastProcessedAssetIdentifier = nil
                    }
                    ScreenshotPipelineStatus.shared.setPipelineFailed(
                        step: "자동 이미지 로드",
                        errorDescription: reason
                    )
                }
                print("❌ ScreenshotMonitor: 이미지 로드 실패 - \(reason)")
                return
            }
            
            print("📤 GPT 파이프라인 실행 중...")
            
            self.processingService.processScreenshot(image: uiImage) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let processingResult):
                        var card = processingResult.card
                        card.sourceScreenshotAssetId = asset.localIdentifier
                        print("📤 ScreenshotMonitor: OCR/GPT 결과 DB 저장 시도 - \(card.title)")
                        if let id = card.thumbnailURL ?? card.screenshotURLs.first {
                            CardImageStore.save(image: uiImage, id: id)
                        }
                        let savedToServer = await self.cardManager.createCard(card)
                        if savedToServer {
                            ScreenshotIndexer.shared.markAssetAsProcessed(asset)
                        }
                        self.showNotification(for: processingResult.card)
                    case .failure(let error):
                        print("❌ 자동 분류 실패: \(error.localizedDescription)")
                    }
                }
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
