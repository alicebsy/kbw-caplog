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

    private let initialImportDoneKey = "ScreenshotIndexer_initialImportDone"
    /// 이미 카드로 만든 스크린샷(asset localIdentifier) — 한 스크린샷당 카드 하나만 생성
    private let processedAssetIdsKey = "ScreenshotIndexer_processedAssetIds"
    private let maxProcessedIds = 500

    private var processedAssetIds: [String] {
        get {
            (UserDefaults.standard.array(forKey: processedAssetIdsKey) as? [String]) ?? []
        }
        set {
            let trimmed = Array(newValue.suffix(maxProcessedIds))
            UserDefaults.standard.set(trimmed, forKey: processedAssetIdsKey)
        }
    }

    /// 지금까지 인식(처리)된 스크린샷 개수 (폴더 등에서 표시용)
    var processedScreenshotCount: Int {
        processedAssetIds.count
    }

    /// 이미 카드로 만든 스크린샷인지 (ScreenshotMonitor에서도 사용)
    func isAssetProcessed(_ asset: PHAsset) -> Bool {
        processedAssetIds.contains(asset.localIdentifier)
    }

    /// 앱 재설치 후 첫 실행 시 로컬 인덱스 초기화 (처리 목록·초기 인덱싱 플래그 삭제)
    static func clearAllProcessedData() {
        UserDefaults.standard.removeObject(forKey: "ScreenshotIndexer_processedAssetIds")
        UserDefaults.standard.removeObject(forKey: "ScreenshotIndexer_initialImportDone")
    }

    /// 스크린샷을 카드로 저장했음을 기록 (한 스크린샷당 카드 하나)
    func markAssetAsProcessed(_ asset: PHAsset) {
        var ids = processedAssetIds
        if !ids.contains(asset.localIdentifier) {
            ids.append(asset.localIdentifier)
            processedAssetIds = ids
        }
    }

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

    /// 플래그 초기화 후 최근 스크린샷 다시 가져오기 (홈에서 "스크린샷에서 카드 가져오기" 버튼용)
    func forceImportRecentScreenshots(limit: Int = 20) async {
        UserDefaults.standard.removeObject(forKey: initialImportDoneKey)
        await importRecentScreenshotsIfNeeded(limit: limit)
    }

    /// 기존 "처리 완료" 목록을 비우고, 최근 스크린샷을 처음부터 다시 인식·OCR·카드 생성 (전부 새로 돌림)
    func resetAndReimportScreenshots(limit: Int = 50) async {
        Self.clearAllProcessedData()
        UserDefaults.standard.removeObject(forKey: initialImportDoneKey)
        await importRecentScreenshotsIfNeeded(limit: limit)
    }

    /// 최근 스크린샷 N개만 인덱싱 (앱 실행 시 기존 스크린샷 반영용). 세션당 1회만 실행.
    /// 연결 대상: 갤러리(사진 앱)의 "스크린샷" 스마트 앨범 = .smartAlbumScreenshots
    func importRecentScreenshotsIfNeeded(limit: Int = 20) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            let msg = "사진 권한 없음. 설정 → Caplog → 사진에서 허용해 주세요."
            await ScreenshotPipelineStatus.shared.setNoScreenshots(reason: msg)
            return
        }
        if UserDefaults.standard.bool(forKey: initialImportDoneKey) {
            await ScreenshotPipelineStatus.shared.setNoScreenshots(reason: "이미 초기 인덱싱 완료됨. '스크린샷에서 카드 가져오기'로 다시 시도 가능.")
            return
        }

        let collections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )
        guard let collection = collections.firstObject else {
            await ScreenshotPipelineStatus.shared.setNoScreenshots(reason: "스크린샷 앨범을 찾을 수 없음 (기기/권한 확인)")
            return
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = min(limit * 2, 100)
        let fetched = PHAsset.fetchAssets(in: collection, options: options)
        var toProcess: [PHAsset] = []
        fetched.enumerateObjects { asset, _, _ in
            if !self.isAssetProcessed(asset) { toProcess.append(asset) }
            if toProcess.count >= limit { return }
        }
        guard !toProcess.isEmpty else {
            await ScreenshotPipelineStatus.shared.setNoScreenshots(reason: "처리할 새 스크린샷 없음 (이미 카드로 만든 것만 있음). 새 스크린샷을 찍은 뒤 다시 시도.")
            UserDefaults.standard.set(true, forKey: initialImportDoneKey)
            return
        }

        await ScreenshotPipelineStatus.shared.setFindingScreenshots(count: toProcess.count)
        for (i, asset) in toProcess.enumerated() {
            await processOne(asset: asset, index: i + 1, total: toProcess.count)
        }
        UserDefaults.standard.set(true, forKey: initialImportDoneKey)
    }

    private func processOne(asset: PHAsset, index: Int, total: Int) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 1080, height: 1920)
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isSynchronous = false
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { [weak self] image, _ in
                guard let self, let uiImage = image else {
                    cont.resume()
                    return
                }
                Task { @MainActor in
                    await ScreenshotPipelineStatus.shared.setImageLoaded(index: index, total: total)
                }
                self.processingService.processScreenshot(image: uiImage) { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let processingResult):
                            let card = processingResult.card
                            print("[Caplog 스크린샷] OCR·GPT 성공 → 카드 생성 단계: \(card.title)")
                            if let id = card.thumbnailURL ?? card.screenshotURLs.first {
                                CardImageStore.save(image: uiImage, id: id)
                            }
                            await ScreenshotPipelineStatus.shared.setOcrGptSuccess(cardTitle: card.title)
                            await self.cardManager.createCard(card)
                            self.markAssetAsProcessed(asset)
                            await self.uploadScreenshotToServer(image: uiImage)
                        case .failure(let err):
                            await ScreenshotPipelineStatus.shared.setPipelineFailed(step: "OCR/GPT", errorDescription: err.localizedDescription)
                        }
                        cont.resume()
                    }
                }
            }
        }
    }
    
    /// asset → UIImage 변환 → GPT 파이프라인 실행 (이미 카드로 만든 스크린샷은 스킵)
    private func process(asset: PHAsset) {
        if isAssetProcessed(asset) { return }
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
                        let card = processingResult.card
                        print("📤 ScreenshotIndexer: OCR/GPT 결과 DB 저장 시도 - \(card.title)")
                        if let id = card.thumbnailURL ?? card.screenshotURLs.first {
                            CardImageStore.save(image: uiImage, id: id)
                        }
                        self.markAssetAsProcessed(asset)
                        Task { @MainActor in
                            await self.cardManager.createCard(card)
                            await self.uploadScreenshotToServer(image: uiImage)
                        }
                    case .failure(let error):
                        print("❌ ScreenshotIndexer: 처리 실패 \(error)")
                    }
                }
            }
        }
    }

    /// 스크린샷 서버 업로드 (DB 저장 → 마이페이지 목록 반영)
    private func uploadScreenshotToServer(image: UIImage) async {
        guard let userNo = try? await UserService().fetchMe().userNo else { return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            ScreenshotUploader.upload(image: image, userId: userNo) { _ in cont.resume() }
        }
    }
}
