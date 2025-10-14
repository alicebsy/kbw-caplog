import Foundation
import Combine
import AuthenticationServices
import GoogleSignIn
import KakaoSDKAuth
import KakaoSDKUser
import UIKit

@MainActor
final class AuthService: NSObject {
    static let shared = AuthService()

    private var appleCompletion: ((Result<ASAuthorizationAppleIDCredential, Error>) -> Void)?

    func signInWithApple(onFinish: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        let provider = ASAuthorizationAppleIDProvider()
        let req = provider.createRequest()
        req.requestedScopes = [.fullName, .email]
        let ctrl = ASAuthorizationController(authorizationRequests: [req])
        ctrl.delegate = self
        ctrl.presentationContextProvider = self
        appleCompletion = onFinish
        ctrl.performRequests()
    }

    func signInWithGoogle(presenting: UIViewController, onFinish: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
            if let error = error { onFinish(.failure(error)); return }
            guard let user = result?.user else { return }
            onFinish(.success(user))
        }
    }

    func signInWithKakao(onFinish: @escaping (Result<OAuthToken, Error>) -> Void) {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { token, error in
                if let error = error { onFinish(.failure(error)) }
                else if let token = token { onFinish(.success(token)) }
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { token, error in
                if let error = error { onFinish(.failure(error)) }
                else if let token = token { onFinish(.success(token)) }
            }
        }
    }
}

extension AuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let cred = authorization.credential as? ASAuthorizationAppleIDCredential {
            appleCompletion?(.success(cred))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleCompletion?(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return keyWindow
        }

        if let activeScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            return activeScene.windows.first ?? UIWindow(windowScene: activeScene)
        }

        guard let anyScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            preconditionFailure("No UIWindowScene available for presentationAnchor.")
        }

        return anyScene.windows.first ?? UIWindow(windowScene: anyScene)
    }
}
