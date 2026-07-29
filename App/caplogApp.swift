import SwiftUI
import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import GoogleSignIn

@main
struct CaplogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    /// 앱 전역 상태 (로그인 여부 등)
    @StateObject private var appState = AppState()

    init() {
        guard let appKey = KakaoConfiguration.nativeAppKey else {
            #if DEBUG
            assertionFailure("Secrets.local.xcconfig에 KAKAO_NATIVE_APP_KEY를 설정하세요.")
            return
            #else
            preconditionFailure("Release 빌드에 KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.")
            #endif
        }
        KakaoSDK.initSDK(appKey: appKey)
    }

    var body: some Scene {
        WindowGroup {
            StartView(appState: appState)
                .environmentObject(appState)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    } else {
                        _ = GIDSignIn.sharedInstance.handle(url)
                    }
                }
                .onChange(of: appState.isLoggedIn) { _, isLoggedIn in
                    updateScreenshotMonitoring(isLoggedIn: isLoggedIn)
                }
        }
    }
    
    /// 로그인한 동안에만 새 스크린샷 자동 분류를 감시합니다.
    private func updateScreenshotMonitoring(isLoggedIn: Bool) {
        Task { @MainActor in
            if isLoggedIn {
                ScreenshotMonitor.shared.startMonitoring()
                print("✅ 스크린샷 자동 분류 활성화됨")
            } else {
                ScreenshotMonitor.shared.stopMonitoring()
                print("⏹️ 로그아웃 상태 - 스크린샷 자동 분류 비활성화")
            }
        }
    }
}

private enum KakaoConfiguration {
    static var nativeAppKey: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("$(") else {
            return nil
        }
        return trimmed
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let hasLaunchedBeforeKey = "caplog.hasLaunchedBefore"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 앱 삭제 후 재설치 시: UserDefaults는 비어 있음. 이때 로그인/로컬 데이터를 초기화해 새로 시작하도록 함.
        if !UserDefaults.standard.bool(forKey: Self.hasLaunchedBeforeKey) {
            SessionStore.clear()
            ScreenshotIndexer.clearLegacyProcessedData()
            UserDefaults.standard.removeObject(forKey: "recentlyViewedCardIDs")
            UserDefaults.standard.removeObject(forKey: "userProfile_nickname")
            UserDefaults.standard.removeObject(forKey: "recent_searches")
            UserDefaults.standard.set(true, forKey: Self.hasLaunchedBeforeKey)
            print("🔄 앱 첫 실행(또는 재설치): 로그인·스크린샷 인덱스·캐시 초기화 완료")
        }
        return true
    }

    @available(iOS, deprecated: 26.0)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return GIDSignIn.sharedInstance.handle(url)
    }
}
