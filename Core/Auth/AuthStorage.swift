import Foundation

protocol AuthStoring {
    var accessToken: String? { get set }
    func clear()
}

final class AuthStorage: AuthStoring {
    private let key = "access_token"
    static let shared = AuthStorage()
    private init() {}

    var accessToken: String? {
        get {
            if let v = UserDefaults.standard.string(forKey: key) { return v }
            return SessionStore.readJWT()
        }
        set {
            if let v = newValue { UserDefaults.standard.set(v, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
    }
    func clear() { accessToken = nil }
}
