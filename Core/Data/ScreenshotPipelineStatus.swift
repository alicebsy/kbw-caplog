//
//  ScreenshotPipelineStatus.swift
//  Caplog
//
//  스크린샷 → OCR → GPT → POST /api/cards 흐름의 마지막 상태를 저장해
//  "스크린샷으로 카드가 만들어졌는지" 앱에서 확인할 수 있게 함.
//

import Combine
import Foundation
import SwiftUI

/// 스크린샷 파이프라인 마지막 실행 결과 (홈 화면에서 확인용)
@MainActor
final class ScreenshotPipelineStatus: ObservableObject {
    static let shared = ScreenshotPipelineStatus()

    @Published var lastMessage: String = "아직 실행 안 함"
    @Published var lastError: String? = nil
    @Published var lastUpdated: Date? = nil
    @Published var lastPostSuccess: Bool? = nil  // true=저장됨, false=실패, nil=미도달

    private init() {}

    func setFindingScreenshots(count: Int) {
        lastMessage = "스크린샷 \(count)개 발견 → 처리 시작"
        lastError = nil
        lastUpdated = Date()
        lastPostSuccess = nil
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setNoScreenshots(reason: String) {
        lastMessage = reason
        lastError = nil
        lastUpdated = Date()
        lastPostSuccess = nil
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setImageLoaded(index: Int, total: Int) {
        lastMessage = "이미지 로드 완료 (\(index)/\(total)) → OCR/GPT 진행 중..."
        lastError = nil
        lastUpdated = Date()
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setOcrGptSuccess(cardTitle: String) {
        lastMessage = "OCR·GPT 완료: \"\(cardTitle)\" → DB 저장 시도(POST)..."
        lastError = nil
        lastUpdated = Date()
        lastPostSuccess = nil
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setPostSending() {
        lastMessage = "POST /api/cards 전송 중..."
        lastError = nil
        lastUpdated = Date()
        print("[Caplog 스크린샷] \(lastMessage)")
    }

    func setPostSuccess(cardTitle: String) {
        lastMessage = "DB 저장 완료: \"\(cardTitle)\""
        lastError = nil
        lastUpdated = Date()
        lastPostSuccess = true
        print("[Caplog 스크린샷] ✅ \(lastMessage)")
    }

    func setPostFailed(errorDescription: String) {
        lastMessage = "카드는 홈에 추가됨 (서버 동기화 실패)"
        lastError = errorDescription
        lastUpdated = Date()
        lastPostSuccess = false
        print("[Caplog 스크린샷] ❌ POST 실패 → 로컬에는 반영됨: \(errorDescription)")
    }

    func setPipelineFailed(step: String, errorDescription: String) {
        lastMessage = "파이프라인 중단: \(step)"
        lastError = errorDescription
        lastUpdated = Date()
        lastPostSuccess = nil
        print("[Caplog 스크린샷] ❌ \(lastMessage) - \(errorDescription)")
    }
}
