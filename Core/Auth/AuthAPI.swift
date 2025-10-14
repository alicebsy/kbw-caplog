import Foundation

enum AuthAPI {
    /// 시뮬레이터면 127.0.0.1 사용
    static let baseURL = URL(string: "http://127.0.0.1:8080/api")!
    // 실기기라면 맥북의 로컬 IP로 교체: "http://192.168.x.x:8080/api"

    // MARK: - DTOs (서버 스펙에 맞춤)
    struct LoginResponse: Decodable {
        let accessToken: String
        let refreshToken: String
    }

    // MARK: - Public APIs

    // 1) 회원가입: 성공만 확인 (Void)
        static func register(name: String, email: String, userId: String, password: String) async throws {
            let body: [String: String] = [
                "name": name, "email": email, "userId": userId, "password": password
            ]
            var req = URLRequest(url: baseURL.appendingPathComponent("auth/signup"))
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                throw NSError(domain: "AuthAPI", code: code, userInfo: [
                    NSLocalizedDescriptionKey: "Signup failed (\(code))"
                ])
            }
            // 바디 내용은 무시 (백엔드가 "회원가입 성공"만 내려줌)
        }

        // 2) 로그인: 토큰 String 반환 (accessToken 또는 jwt 키 지원)
        static func login(email: String, password: String) async throws -> String {
            let body = ["email": email, "password": password]
            var req = URLRequest(url: baseURL.appendingPathComponent("auth/login"))
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                throw NSError(domain: "AuthAPI", code: code, userInfo: [
                    NSLocalizedDescriptionKey: "Login failed (\(code))"
                ])
            }

            // {"accessToken": "...", "refreshToken": "..."} or {"jwt": "..."}
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let token = obj["accessToken"] as? String { return token }
                if let token = obj["jwt"] as? String { return token }
            }
            throw NSError(domain: "AuthAPI", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Token not found in response"
            ])
        }

    // 필요 시 추가 (지금은 백엔드 미구현)
    static func exchangeApple(idToken: String) async throws -> String {
        struct AppleReq: Encodable { let idToken: String }
        let res: LoginResponse = try await postJSON(path: "/auth/apple", body: AppleReq(idToken: idToken))
        return res.accessToken
    }
    static func exchangeGoogle(idToken: String) async throws -> String {
        struct GoogleReq: Encodable { let idToken: String }
        let res: LoginResponse = try await postJSON(path: "/auth/google", body: GoogleReq(idToken: idToken))
        return res.accessToken
    }
    static func exchangeKakao(accessToken: String) async throws -> String {
        struct KakaoReq: Encodable { let accessToken: String }
        let res: LoginResponse = try await postJSON(path: "/auth/kakao", body: KakaoReq(accessToken: accessToken))
        return res.accessToken
    }

    // MARK: - Low-level helpers

    /// 단순 문자열 응답(회원가입 “회원가입 성공” 등)
    private static func postString(path: String, body: some Encodable) async throws -> String {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(AnyEncodable(body))

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AuthAPI", code: code, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(code)"
            ])
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// JSON 응답을 디코딩
    private static func postJSON<T: Decodable>(path: String, body: some Encodable) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        req.httpBody = try enc.encode(AnyEncodable(body))

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(code)"
            throw NSError(domain: "AuthAPI", code: code, userInfo: [
                NSLocalizedDescriptionKey: msg
            ])
        }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(T.self, from: data)
    }
}

/// Encodable 제네릭 우회용 래퍼
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ wrapped: T) { _encode = wrapped.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
