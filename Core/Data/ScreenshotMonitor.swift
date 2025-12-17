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
    
    /// 모니터링 시작
    func startMonitoring() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        guard status == .authorized || status == .limited else {
            print("❌ ScreenshotMonitor: 사진 권한 없음")
            return
        }
        
        // 스크린샷 컬렉션 찾기
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )
        
        screenshotCollection = collections.firstObject
        
        // 변경 감지 등록
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
        guard let collection = screenshotCollection else { return }
        
        // 스크린샷 컬렉션 변경 확인
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let screenshots = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        
        guard let changeDetails = changeInstance.changeDetails(for: screenshots),
              changeDetails.hasIncrementalChanges else {
            return
        }
        
        // 새로 추가된 스크린샷 처리
        let insertedIndexes = changeDetails.insertedIndexes
        guard let insertedIndexes = insertedIndexes, !insertedIndexes.isEmpty else {
            return
        }
        
        print("📸 새 스크린샷 감지: \(insertedIndexes.count)개")
        
        insertedIndexes.forEach { index in
            let asset = changeDetails.fetchResultAfterChanges.object(at: index)
            
            // 중복 처리 방지
            if lastProcessedAssetIdentifier == asset.localIdentifier {
                print("⏭️ 이미 처리한 스크린샷: \(asset.localIdentifier)")
                return
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
                        print("✅ 자동 분류 완료!")
                        print("   제목: \(processingResult.card.title)")
                        print("   카테고리: \(processingResult.card.category.rawValue)")
                        print("   서브카테고리: \(processingResult.card.subcategory)")
                        
                        // 카드 저장
                        await self.cardManager.createCard(processingResult.card)
                        
                        // 알림 표시 (선택사항)
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
