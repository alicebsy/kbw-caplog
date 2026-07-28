import Foundation

// MARK: - Error

enum APIError: LocalizedError {
    case unauthorized
    case decodeFailed
    case server(String)
    case network(Error)
    case invalidResponse
    case timeout

    var errorDescription: String? {
        switch self {
        case .unauthorized:     return "인증이 만료되었습니다."
        case .decodeFailed:     return "서버 응답 파싱에 실패했습니다."
        case .server(let msg):  return msg
        case .network(let err): return err.localizedDescription
        case .invalidResponse:  return "유효하지 않은 서버 응답입니다."
        case .timeout:          return "요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요."
        }
    }
}

// MARK: - Client

struct APIClient {
    var authStore: AuthStoring = AuthStorage.shared
    var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30  // ✅ 요청 타임아웃: 30초
        config.timeoutIntervalForResource = 60 // ✅ 리소스 타임아웃: 60초
        return URLSession(configuration: config)
    }()

    // 공용 인코더/디코더 (ISO-8601 날짜 처리)
    private var encoder: JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }
    private var decoder: JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractionalFormatter.date(from: value) {
                return date
            }

            let standardFormatter = ISO8601DateFormatter()
            standardFormatter.formatOptions = [.withInternetDateTime]
            if let date = standardFormatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "지원하지 않는 ISO-8601 날짜 형식입니다: \(value)"
            )
        }
        return dec
    }

    // 빈 바디 표현용
    private struct NoBody: Encodable {}
    // 빈 응답 표현용
    private struct EmptyResponse: Decodable {}

    // MARK: 1) 일반 요청 (Body 있는 경우)
    func request<T: Decodable, B: Encodable>(
        _ method: String,
        path: String,
        query: [URLQueryItem]? = nil,
        body: B? = Optional<B>.none,
        authorized: Bool = true,
        timeoutInterval: TimeInterval = 30
    ) async throws -> T {
        var url = APIConfig.baseURL
        url.append(path: APIConfig.apiPrefix + path)
        if let query { url.append(queryItems: query) }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        // ✅ 타임아웃 명시적 설정
        req.timeoutInterval = timeoutInterval

        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)
        }

        if authorized, let token = authStore.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, resp) = try await urlSession.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse }

            switch http.statusCode {
            case 200..<300:
                // 204 / 빈 본문 허용
                if http.statusCode == 204 || data.isEmpty {
                    // 호출부에서 EmptyResponse를 기대하면 정상 반환
                    if T.self == EmptyResponse.self {
                        return EmptyResponse() as! T
                    }
                    // 그 외 타입인데 본문이 비어있으면 파싱 실패로 처리
                    throw APIError.decodeFailed
                }
                do { return try decoder.decode(T.self, from: data) }
                catch {
                    print("❌ Decode error: \(error)")
                    print("📦 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                    throw APIError.decodeFailed
                }

            case 401:
                if authorized {
                    SessionStore.clear()
                    await MainActor.run {
                        NotificationCenter.default.post(name: .sessionExpired, object: nil)
                    }
                }
                throw APIError.unauthorized

            default:
                let msg = String(data: data, encoding: .utf8) ?? "Status \(http.statusCode)"
                print("❌ Server error: \(msg)")
                throw APIError.server(msg)
            }
        } catch let error as URLError {
            // ✅ 타임아웃 에러 명시적 처리
            if error.code == .timedOut {
                throw APIError.timeout
            }
            throw APIError.network(error)
        } catch {
            if let apiErr = error as? APIError { throw apiErr }
            throw APIError.network(error)
        }
    }

    // MARK: 2) 일반 요청 (Body 없는 버전)  👉 B 추론 실패 방지용
    func request<T: Decodable>(
        _ method: String,
        path: String,
        query: [URLQueryItem]? = nil,
        authorized: Bool = true
    ) async throws -> T {
        // body 파라미터를 아예 제거한 오버로드
        try await request(method, path: path, query: query, body: Optional<NoBody>.none, authorized: authorized)
    }

    // MARK: 3) Void 응답 (204 등) - Body 없는 버전
    func requestVoid(
        _ method: String,
        path: String,
        authorized: Bool = true
    ) async throws {
        // EmptyResponse를 기대 타입으로 호출 → 204/빈 본문 처리
        let _: EmptyResponse = try await request(method, path: path, query: nil, body: Optional<NoBody>.none, authorized: authorized)
    }

    // MARK: 4) Void 응답 (204 등) - Body 있는 버전
    func requestVoid<B: Encodable>(
        _ method: String,
        path: String,
        body: B,
        authorized: Bool = true
    ) async throws {
        let _: EmptyResponse = try await request(method, path: path, query: nil, body: body, authorized: authorized)
    }
}
