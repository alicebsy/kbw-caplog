import SwiftUI
import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import GoogleSignIn
import Photos

@main
struct CaplogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        KakaoSDK.initSDK(appKey: "81b506b612e5cc41201bc15a145764cb")
    }

    var body: some Scene {
        WindowGroup {
            StartView()
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
