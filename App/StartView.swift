import SwiftUI

/// 앱 진입점 루트 뷰
/// - appState.isLoggedIn: 로그인/회원가입 플로우 완료 여부
/// - true → AppNavigation(탭바: 홈/폴더/검색/공유/마이페이지)
/// - false → Register1View(Join / Log in)
struct StartView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoggedIn {
                // 로그인 완료 → 탭바 메인 화면
                AppNavigation()
            } else {
                // 로그인 전 → 회원가입/로그인 화면
                Register1View(appState: appState)
            }
        }
        .onAppear {
            // 앱 시작 시 기존 JWT 있으면 자동 로그인
            appState.checkExistingSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .logoutCompleted)) { _ in
            appState.logout()
        }
    }
}
