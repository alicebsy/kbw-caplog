//
//  ScreenshotPipelineStatus.swift
//  Caplog
//
//  스크린샷 → OCR → GPT → POST /api/cards 흐름의 마지막 상태를 저장해
//  "스크린샷으로 카드가 만들어졌는지" 앱에서 확인할 수 있게 함.
//

import Combine
import Foundation

/// 스크린샷 카드 생성 진행 상태
@MainActor
final class ScreenshotPipelineStatus: ObservableObject {
    static let shared = ScreenshotPipelineStatus()

    enum Phase {
        case idle
        case running
        case success
        case warning
        case failure
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var lastMessage: String = "아직 실행하지 않았어요."
    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var totalCount = 0
    @Published private(set) var currentCount = 0
    @Published private(set) var successCount = 0
    @Published private(set) var failureCount = 0
    @Published private(set) var syncWarningCount = 0

    var isRunning: Bool { phase == .running }
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(totalCount), 1)
    }

    private init() {}

    func setFindingScreenshots(count: Int) {
        phase = .running
        totalCount = count
        currentCount = 0
        successCount = 0
        failureCount = 0
        syncWarningCount = 0
        lastMessage = "스크린샷 \(count)장으로 카드를 만들고 있어요."
        lastError = nil
        lastUpdated = Date()
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setNoScreenshots(reason: String) {
        phase = .idle
        lastMessage = reason
        lastError = nil
        lastUpdated = Date()
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setImageLoaded(index: Int, total: Int) {
        phase = .running
        totalCount = total
        currentCount = index
        lastMessage = "\(index)/\(total)번째 스크린샷의 내용을 읽고 있어요."
        lastError = nil
        lastUpdated = Date()
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setOcrGptSuccess(cardTitle: String) {
        phase = .running
        lastMessage = "‘\(cardTitle)’ 카드를 저장하고 있어요."
        lastError = nil
        lastUpdated = Date()
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setPostSending() {
        phase = .running
        lastMessage = "카드를 안전하게 저장하고 있어요."
        lastError = nil
        lastUpdated = Date()
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setPostSuccess(cardTitle: String) {
        phase = .running
        successCount += 1
        lastMessage = "‘\(cardTitle)’ 카드를 만들었어요."
        lastError = nil
        lastUpdated = Date()
        print("[Caplog 스크린샷] ✅ \(lastMessage)")
    }

    func setPostFailed(errorDescription: String) {
        phase = .running
        successCount += 1
        syncWarningCount += 1
        lastMessage = "카드는 기기에 저장했지만 서버 동기화에 실패했어요."
        lastError = errorDescription
        lastUpdated = Date()
        print("[Caplog 스크린샷] ❌ POST 실패 → 로컬에는 반영됨: \(errorDescription)")
    }

    func setPipelineFailed(step: String, errorDescription: String) {
        phase = .running
        failureCount += 1
        lastMessage = "\(step) 단계에서 카드 생성에 실패했어요."
        lastError = errorDescription
        lastUpdated = Date()
        print("[Caplog 스크린샷] ❌ \(lastMessage) - \(errorDescription)")
    }

    func setCompleted() {
        lastUpdated = Date()
        if failureCount == 0 && syncWarningCount == 0 {
            phase = .success
            lastMessage = "\(successCount)장의 카드 생성을 완료했어요."
            lastError = nil
        } else if successCount > 0 {
            phase = .warning
            if failureCount > 0 {
                lastMessage = "\(successCount)장은 완료했고 \(failureCount)장은 만들지 못했어요."
            } else {
                lastMessage = "\(successCount)장은 기기에 저장했지만 서버 동기화가 필요해요."
            }
        } else {
            phase = .failure
            lastMessage = "카드를 만들지 못했어요. 다시 시도해주세요."
        }
        print("[Caplog 스크린샷] \(lastMessage)")
    }
}
