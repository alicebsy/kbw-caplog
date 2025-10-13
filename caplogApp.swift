import SwiftUI
import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import GoogleSignIn

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
