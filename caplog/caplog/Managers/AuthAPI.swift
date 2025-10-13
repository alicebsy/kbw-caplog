import Foundation

enum AuthAPI {
    // TODO: 실제 백엔드 도메인으로 교체
    static let baseURL = URL(string: "https://YOUR_BACKEND_DOMAIN")!

    static func register(name: String, email: String, userId: String, password: String) async throws -> String {
        let body: [String: String] = [
            "name": name, "email": email, "userId": userId, "password": password
        ]
        return try await post(path: "/auth/register", body: body)
    }

    static func login(email: String, password: String) async throws -> String {
        let body: [String: String] = [
            "email": email, "password": password
        ]
        return try await post(path: "/auth/login", body: body)
    }

    static func exchangeApple(idToken: String) async throws -> String {
        try await post(path: "/auth/apple", body: ["idToken": idToken])
    }

    static func exchangeGoogle(idToken: String) async throws -> String {
        try await post(path: "/auth/google", body: ["idToken": idToken])
    }

    static func exchangeKakao(accessToken: String) async throws -> String {
        try await post(path: "/auth/kakao", body: ["accessToken": accessToken])
    }

    private static func post(path: String, body: [String: String]) async throws -> String {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AuthAPI", code: code, userInfo: [
                NSLocalizedDescriptionKey: "AuthAPI error (\(code))"
            ])
        }
        // 우선 jwt 키만 뽑아서 반환
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = obj["jwt"] as? String {
            return token
        }
        // 혹시 서버가 {"jwt":"..."} 형태로 주지 않는다면 Decodable 시도
        if let decoded = try? JSONDecoder().decode(AuthResponse.self, from: data) {
            return decoded.jwt
        }
        throw NSError(domain: "AuthAPI", code: -2, userInfo: [
            NSLocalizedDescriptionKey: "JWT not found in response"
        ])
    }
}
