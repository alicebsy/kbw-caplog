import Foundation

// MARK: - 환경 스위치
enum BackendEnv {
    /// 서버 없이 앱만 돌릴 때 true. 실제 서버 붙일 땐 false로 바꾸기,
    static var isMock: Bool = true
}


// MARK: - AuthAPI
enum AuthAPI {
    static let baseURL = APIConfig.baseURL

    // MARK: - DTOs (서버 스펙에 맞춤)
    struct LoginResponse: Decodable {
        let accessToken: String
        let refreshToken: String
    }

    // MARK: - Public APIs

    /// 회원가입 (성공만 확인)
    static func register(name: String, email: String, userId: String, password: String) async throws {
        // ✨ isMock이 true일 때 실제 네트워크 통신을 건너뛰는 코드를 추가합니다.
        if BackendEnv.isMock {
            print("--- Mock: Register Succeeded ---")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기 (로딩 인디케이터 확인용)
            return
        }
        
        let body: [String: String] = [
            "name": name, "email": email, "userId": userId, "password": password
        ]

        var url = baseURL
        url.append(path: APIConfig.apiPrefix)      // "/api"
        url.append(path: "auth/signup")            // "/api/auth/signup"

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AuthAPI", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "Signup failed (\(code))"])
        }
    }

    /// 로그인: 액세스 토큰 문자열 반환 (서버가 accessToken 또는 jwt 중 하나로 줄 수 있음)
    static func login(email: String, password: String) async throws -> String {
        // ✨ isMock이 true일 때 가짜 토큰을 즉시 반환하는 코드를 추가합니다.
        if BackendEnv.isMock {
            print("--- Mock: Login Succeeded ---")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
            return "mock_jwt_token_for_test" // 가짜 토큰 반환
        }

        let body = ["email": email, "password": password]

        var url = baseURL
        url.append(path: APIConfig.apiPrefix)      // "/api"
        url.append(path: "auth/login")             // "/api/auth/login"

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AuthAPI", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "Login failed (\(code))"])
        }

        // {"accessToken":"..." , "refreshToken":"..."} or {"jwt":"..."}
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let token = obj["accessToken"] as? String { return token }
            if let token = obj["jwt"] as? String { return token }
        }
        throw NSError(domain: "AuthAPI", code: -2,
                      userInfo: [NSLocalizedDescriptionKey: "Token not found in response"])
    }

    // (선택) 소셜 교환 엔드포인트 — 동일하게 /api 프리픽스 포함
    static func exchangeApple(idToken: String) async throws -> String {
        struct Req: Encodable { let idToken: String }
        let res: LoginResponse = try await postJSON(path: "auth/apple", body: Req(idToken: idToken))
        return res.accessToken
    }
    static func exchangeGoogle(idToken: String) async throws -> String {
        struct Req: Encodable { let idToken: String }
        let res: LoginResponse = try await postJSON(path: "auth/google", body: Req(idToken: idToken))
        return res.accessToken
    }
    static func exchangeKakao(accessToken: String) async throws -> String {
        struct Req: Encodable { let accessToken: String }
        let res: LoginResponse = try await postJSON(path: "auth/kakao", body: Req(accessToken: accessToken))
        return res.accessToken
    }

    // MARK: - Low-level helpers (항상 /api 프리픽스를 붙여서 호출)

    private static func postString(path: String, body: some Encodable) async throws -> String {
        var url = baseURL
        url.append(path: APIConfig.apiPrefix)
        url.append(path: path)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONEncoder().encode(AnyEncodable(body))

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AuthAPI", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(code)"])
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func postJSON<T: Decodable>(path: String, body: some Encodable) async throws -> T {
        var url = baseURL
        url.append(path: APIConfig.apiPrefix)
        url.append(path: path)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        req.httpBody = try enc.encode(AnyEncodable(body))

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(code)"
            throw NSError(domain: "AuthAPI", code: code,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(T.self, from: data)
    }
}
