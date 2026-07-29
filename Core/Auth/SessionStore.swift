//
//  SessionStore.swift
//  caplog
//
//  Created by user on 10/5/25.
//


import Foundation
import CryptoKit
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

    /// JWT subject(email)를 직접 저장하지 않고 해시한 계정별 로컬 저장 범위입니다.
    static func currentAccountStorageScope() -> String? {
        guard let token = readJWT(),
              let subject = jwtSubject(from: token) else {
            return nil
        }
        let digest = SHA256.hash(data: Data(subject.utf8))
        return digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    static func clear() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: "access_token")
    }

    private static func jwtSubject(from token: String) -> String? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }

        var encodedPayload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingCount = (4 - encodedPayload.count % 4) % 4
        encodedPayload += String(repeating: "=", count: paddingCount)

        guard let data = Data(base64Encoded: encodedPayload),
              let object = try? JSONSerialization.jsonObject(with: data),
              let json = object as? [String: Any],
              let subject = json["sub"] as? String,
              !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return subject.lowercased()
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
