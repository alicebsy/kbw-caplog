//
//  ScreenshotIndexer.swift
//  Caplog
//
//  Created by ChatGPT on 2025/12/02.
//

import Foundation
import Photos
import UIKit

@MainActor
final class ScreenshotIndexer {
    static let shared = ScreenshotIndexer()
    
    private let processingService = ScreenshotProcessingService()
    private let cardManager = CardManager.shared
    
    private init() {}
    
    /// 갤러리에서 스크린샷만 자동으로 인덱싱해 카드에 저장
    func importAllScreenshots() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        guard status == .authorized || status == .limited else {
            print("❌ ScreenshotIndexer: 권한 없음")
            return
        }
        
        print("📸 ScreenshotIndexer: 스크린샷 인덱싱 시작")
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )
        
        collections.enumerateObjects { collection, _, _ in
            let assets = PHAsset.fetchAssets(in: collection, options: options)
            assets.enumerateObjects { asset, _, _ in
                self.process(asset: asset)
            }
        }
    }
    
    /// asset → UIImage 변환 → GPT 파이프라인 실행
    private func process(asset: PHAsset) {
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 1080, height: 1920)
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = false
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: requestOptions
        ) { [weak self] image, _ in
            guard let self, let uiImage = image else {
                print("❌ ScreenshotIndexer: 이미지 로드 실패")
                return
            }
            
            print("📸 ScreenshotIndexer: 스크린샷 분석 시작")
            
            self.processingService.processScreenshot(image: uiImage) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let processingResult):
                        print("✨ GPT 결과 생성 완료 → 카드 저장")
                        Task { @MainActor in
                            await self.cardManager.createCard(processingResult.card)
                        }
                        
                    case .failure(let error):
                        print("❌ ScreenshotIndexer: 처리 실패 \(error)")
                    }
                }
            }
        }
    }
}
