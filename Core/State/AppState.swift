//
//  AppState.swift
//  caplog
//
//  앱 전역 로그인 상태 관리
//  - Register 플로우 완료 시 isLoggedIn = true → StartView에서 AppNavigation(탭바) 표시
//  - 앱 시작 시 Keychain에 JWT 있으면 자동 로그인
//

import Foundation
import SwiftUI
import Combine

/// 앱 전역 상태 (로그인 여부)
/// - ObservableObject로 뷰에 바인딩
/// - Register4_3 "모두 완료" 시 isLoggedIn = true 설정
final class AppState: ObservableObject {
    
    /// 로그인 완료 여부 (true면 탭바 메인 화면 표시)
    @Published var isLoggedIn: Bool = false
    
    /// 앱 시작 시 JWT 있으면 자동 로그인 처리
    func checkExistingSession() {
        if SessionStore.readJWT() != nil {
            isLoggedIn = true
        }
    }
    
    /// 로그아웃 시 호출
    func logout() {
        SessionStore.clear()
        AuthStorage.shared.clear()
        isLoggedIn = false
    }
}
