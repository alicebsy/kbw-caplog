//
//  SessionStore.swift
//  caplog
//
//  Created by user on 10/5/25.
//


import Foundation
import Security

enum SessionStore {
    private static let accessTokenKey = "caplog.jwt"
    private static let refreshTokenKey = "caplog.refresh-token"

    static func save(accessToken: String, refreshToken: String?) {
        save(accessToken, key: accessTokenKey)
        if let refreshToken {
            save(refreshToken, key: refreshTokenKey)
        } else {
            delete(key: refreshTokenKey)
        }
        // 이전 버전에서 UserDefaults에 저장했던 토큰은 제거한다.
        UserDefaults.standard.removeObject(forKey: "access_token")
    }

    static func saveJWT(_ token: String) {
        save(accessToken: token, refreshToken: nil)
    }

    static func readJWT() -> String? {
        read(key: accessTokenKey)
    }

    static func readRefreshToken() -> String? {
        read(key: refreshTokenKey)
    }

    static func clear() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: "access_token")
    }

    private static func save(_ token: String, key: String) {
        let data = token.data(using: .utf8)!
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(q as CFDictionary)
        var add = q
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func read(key: String) -> String? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(key: String) {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(q as CFDictionary)
    }
}
