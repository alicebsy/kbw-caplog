import SwiftUI
import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import GoogleSignIn
import Photos

@main
struct CaplogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    /// 앱 전역 상태 (로그인 여부 등)
    @StateObject private var appState = AppState()

    init() {
        KakaoSDK.initSDK(appKey: "81b506b612e5cc41201bc15a145764cb")
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
                .onAppear {
                    setupScreenshotMonitoring()
                }
        }
    }
    
    /// 스크린샷 자동 분류 모니터링 시작
    private func setupScreenshotMonitoring() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if status == .authorized || status == .limited {
            // 이미 권한이 있으면 바로 시작
            Task { @MainActor in
                ScreenshotMonitor.shared.startMonitoring()
                print("✅ 스크린샷 자동 분류 활성화됨")
            }
        } else if status == .notDetermined {
            // 권한 요청 후 시작
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    Task { @MainActor in
                        ScreenshotMonitor.shared.startMonitoring()
                        print("✅ 스크린샷 자동 분류 활성화됨")
                    }
                }
            }
        } else {
            print("⚠️ 사진 권한 없음 - 스크린샷 자동 분류 비활성화")
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let hasLaunchedBeforeKey = "caplog.hasLaunchedBefore"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 앱 삭제 후 재설치 시: UserDefaults는 비어 있음. 이때 로그인/로컬 데이터를 초기화해 새로 시작하도록 함.
        if !UserDefaults.standard.bool(forKey: Self.hasLaunchedBeforeKey) {
            SessionStore.clear()
            ScreenshotIndexer.clearAllProcessedData()
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
