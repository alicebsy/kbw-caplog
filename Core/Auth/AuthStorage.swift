import Foundation

protocol AuthStoring {
    var accessToken: String? { get set }
    func clear()
}

final class AuthStorage: AuthStoring {
    static let shared = AuthStorage()
    private init() {}

    var accessToken: String? {
        get {
            if let token = SessionStore.readJWT() {
                return token
            }
            // 기존 앱 버전의 UserDefaults 토큰을 Keychain으로 한 번만 이전한다.
            if let legacyToken = UserDefaults.standard.string(forKey: "access_token") {
                SessionStore.saveJWT(legacyToken)
                return legacyToken
            }
            return nil
        }
        set {
            if let newValue {
                SessionStore.saveJWT(newValue)
            } else {
                SessionStore.clear()
            }
        }
    }
    func clear() { SessionStore.clear() }
}
