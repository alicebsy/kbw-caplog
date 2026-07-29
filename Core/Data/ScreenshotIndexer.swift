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

    private static let legacyInitialImportDoneKey = "ScreenshotIndexer_initialImportDone"
    private static let legacyProcessedAssetIdsKey = "ScreenshotIndexer_processedAssetIds"
    /// 이미 카드로 만든 스크린샷(asset localIdentifier) — 한 스크린샷당 카드 하나만 생성
    private let maxProcessedIds = 500

    private struct AccountKeys {
        let initialImportDone: String
        let processedAssetIds: String
        let legacyMigrationDone: String
    }

    private var accountKeys: AccountKeys? {
        guard let scope = SessionStore.currentAccountStorageScope() else { return nil }
        return AccountKeys(
            initialImportDone: "ScreenshotIndexer.\(scope).initialImportDone",
            processedAssetIds: "ScreenshotIndexer.\(scope).processedAssetIds",
            legacyMigrationDone: "ScreenshotIndexer.\(scope).legacyMigrationDone"
        )
    }

    private var processedAssetIds: [String] {
        get {
            migrateLegacyDataIfNeeded()
            guard let keys = accountKeys else { return [] }
            return (UserDefaults.standard.array(forKey: keys.processedAssetIds) as? [String]) ?? []
        }
        set {
            migrateLegacyDataIfNeeded()
            guard let keys = accountKeys else { return }
            let trimmed = Array(newValue.suffix(maxProcessedIds))
            UserDefaults.standard.set(trimmed, forKey: keys.processedAssetIds)
        }
    }

    /// 지금까지 인식(처리)된 스크린샷 개수 (폴더 등에서 표시용)
    var processedScreenshotCount: Int {
        processedAssetIds.count
    }

    /// 갤러리(스크린샷 앨범/최근 항목)에 있는 스크린샷 전체 개수 (비동기, 폴더 등에서 표시용)
    static func fetchGalleryScreenshotCount() async -> Int {
        guard let collection = ScreenshotMonitor.findScreenshotCollection(
            allowSimulatorFallback: false
        ) else { return 0 }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(in: collection, options: options)
        return result.count
    }

    /// 이미 카드로 만든 스크린샷인지 (ScreenshotMonitor에서도 사용)
    func isAssetProcessed(_ asset: PHAsset) -> Bool {
        processedAssetIds.contains(asset.localIdentifier)
    }

    /// 현재 로그인 계정의 처리 목록·초기 인덱싱 플래그만 삭제합니다.
    static func clearCurrentAccountProcessedData() {
        guard let scope = SessionStore.currentAccountStorageScope() else { return }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "ScreenshotIndexer.\(scope).processedAssetIds")
        defaults.removeObject(forKey: "ScreenshotIndexer.\(scope).initialImportDone")
    }

    /// 계정별 키 도입 전 사용하던 공용 처리 기록을 삭제합니다.
    static func clearLegacyProcessedData() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: legacyProcessedAssetIdsKey)
        defaults.removeObject(forKey: legacyInitialImportDoneKey)
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
        guard let keys = accountKeys else {
            ScreenshotPipelineStatus.shared.setNoScreenshots(
                reason: "로그인 정보를 확인할 수 없어 스크린샷을 가져오지 못했어요."
            )
            return
        }
        UserDefaults.standard.removeObject(forKey: keys.initialImportDone)
        await importRecentScreenshotsIfNeeded(limit: limit)
    }

    /// 기존 "처리 완료" 목록을 비우고, 최근 스크린샷을 처음부터 다시 인식·OCR·카드 생성 (전부 새로 돌림)
    func resetAndReimportScreenshots(limit: Int = 50) async {
        Self.clearCurrentAccountProcessedData()
        await importRecentScreenshotsIfNeeded(limit: limit)
    }

    /// 최근 스크린샷 N개만 인덱싱 (앱 실행 시 기존 스크린샷 반영용). 세션당 1회만 실행.
    /// 연결 대상: 갤러리(사진 앱)의 "스크린샷" 스마트 앨범 = .smartAlbumScreenshots
    func importRecentScreenshotsIfNeeded(limit: Int = 20) async {
        migrateLegacyDataIfNeeded()
        guard let keys = accountKeys else {
            ScreenshotPipelineStatus.shared.setNoScreenshots(
                reason: "로그인 후 스크린샷을 가져올 수 있어요."
            )
            return
        }
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            let msg = "사진 권한 없음. 설정 → Caplog → 사진에서 허용해 주세요."
            ScreenshotPipelineStatus.shared.setNoScreenshots(reason: msg)
            return
        }
        if UserDefaults.standard.bool(forKey: keys.initialImportDone) {
            ScreenshotPipelineStatus.shared.setNoScreenshots(
                reason: "새로운 스크린샷이 생기면 자동으로 확인할게요."
            )
            return
        }

        guard let collection = ScreenshotMonitor.findScreenshotCollection() else {
            ScreenshotPipelineStatus.shared.setNoScreenshots(
                reason: "스크린샷 앨범을 찾지 못했어요. 사진 접근 권한을 확인해주세요."
            )
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
            ScreenshotPipelineStatus.shared.setNoScreenshots(
                reason: "새로 가져올 스크린샷이 없어요. 이미 만든 카드는 건너뛰었어요."
            )
            UserDefaults.standard.set(true, forKey: keys.initialImportDone)
            return
        }

        ScreenshotPipelineStatus.shared.setFindingScreenshots(count: toProcess.count)
        for (i, asset) in toProcess.enumerated() {
            await processOne(asset: asset, index: i + 1, total: toProcess.count)
        }
        ScreenshotPipelineStatus.shared.setCompleted()
        UserDefaults.standard.set(true, forKey: keys.initialImportDone)
    }

    /// 업데이트 전 공용 처리 기록은 최초 로그인한 계정으로 한 번만 이전합니다.
    private func migrateLegacyDataIfNeeded() {
        guard let keys = accountKeys else { return }
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: keys.legacyMigrationDone) else { return }

        if defaults.object(forKey: keys.processedAssetIds) == nil,
           let legacyIds = defaults.array(forKey: Self.legacyProcessedAssetIdsKey) as? [String] {
            defaults.set(Array(legacyIds.suffix(maxProcessedIds)), forKey: keys.processedAssetIds)
        }
        if defaults.object(forKey: keys.initialImportDone) == nil,
           defaults.bool(forKey: Self.legacyInitialImportDoneKey) {
            defaults.set(true, forKey: keys.initialImportDone)
        }

        defaults.set(true, forKey: keys.legacyMigrationDone)
        Self.clearLegacyProcessedData()
    }

    private func processOne(asset: PHAsset, index: Int, total: Int) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 1080, height: 1920)
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isSynchronous = false
            // iCloud 다운로드 없이 기기에 원본이 있는 사진만 처리합니다.
            requestOptions.isNetworkAccessAllowed = false
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { [weak self] image, info in
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                guard !isDegraded else { return }

                let isCancelled = info?[PHImageCancelledKey] as? Bool ?? false
                let imageError = info?[PHImageErrorKey] as? Error
                guard let self, !isCancelled, imageError == nil, let uiImage = image else {
                    Task { @MainActor in
                        let reason = imageError?.localizedDescription
                            ?? (isCancelled ? "사진 요청이 취소되었습니다." : "사진 데이터를 불러오지 못했습니다.")
                        ScreenshotPipelineStatus.shared.setPipelineFailed(
                            step: "이미지 로드",
                            errorDescription: reason
                        )
                        cont.resume()
                    }
                    return
                }
                Task { @MainActor in
                    ScreenshotPipelineStatus.shared.setImageLoaded(index: index, total: total)
                    self.processingService.processScreenshot(image: uiImage) { result in
                        Task { @MainActor in
                            switch result {
                            case .success(let processingResult):
                                var card = processingResult.card
                                card.sourceScreenshotAssetId = asset.localIdentifier
                                print("[Caplog 스크린샷] OCR·GPT 성공 → 카드 생성 단계: \(card.title)")
                                if let id = card.thumbnailURL ?? card.screenshotURLs.first {
                                    CardImageStore.save(image: uiImage, id: id)
                                }
                                ScreenshotPipelineStatus.shared.setOcrGptSuccess(cardTitle: card.title)
                                let savedToServer = await self.cardManager.createCard(card)
                                if savedToServer {
                                    self.markAssetAsProcessed(asset)
                                }
                            case .failure(let err):
                                ScreenshotPipelineStatus.shared.setPipelineFailed(
                                    step: "내용 분석",
                                    errorDescription: err.localizedDescription
                                )
                            }
                            cont.resume()
                        }
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
                    ?? (isCancelled ? "사진 요청 취소" : "사진 데이터 없음")
                print("❌ ScreenshotIndexer: 이미지 로드 실패 - \(reason)")
                return
            }
            print("📸 ScreenshotIndexer: 스크린샷 분석 시작")
            self.processingService.processScreenshot(image: uiImage) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let processingResult):
                        var card = processingResult.card
                        card.sourceScreenshotAssetId = asset.localIdentifier
                        print("📤 ScreenshotIndexer: OCR/GPT 결과 DB 저장 시도 - \(card.title)")
                        if let id = card.thumbnailURL ?? card.screenshotURLs.first {
                            CardImageStore.save(image: uiImage, id: id)
                        }
                        Task { @MainActor in
                            let savedToServer = await self.cardManager.createCard(card)
                            if savedToServer {
                                self.markAssetAsProcessed(asset)
                            }
                        }
                    case .failure(let error):
                        print("❌ ScreenshotIndexer: 처리 실패 \(error)")
                    }
                }
            }
        }
    }

}
