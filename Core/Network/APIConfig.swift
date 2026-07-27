import Foundation

/// API 기본 설정
/// - Debug: 설정값이 없으면 시뮬레이터=localhost, 실기기=개발용 로컬 IP
/// - Release: CAPLOG_API_BASE_URL에 설정된 HTTPS 주소만 사용
/// - apiPrefix: /api (모든 엔드포인트 앞에 붙음)
enum APIConfig {
    static let baseURL: URL = {
        if let configuredURL = configuredBaseURL {
            #if !DEBUG
            guard configuredURL.scheme?.lowercased() == "https" else {
                preconditionFailure("Release 빌드의 CAPLOG_API_BASE_URL은 HTTPS 주소여야 합니다.")
            }
            #endif
            return configuredURL
        }

        #if DEBUG
        #if targetEnvironment(simulator)
        // 시뮬레이터의 기본 개발 서버
        return URL(string: "http://127.0.0.1:8080")!
        #else
        // 실기기 개발 시 CAPLOG_API_BASE_URL 설정을 권장합니다.
        // TODO: 현재 네트워크 환경의 맥북 IP로 변경 필요
        return URL(string: "http://192.168.0.14:8080")!
        #endif
        #else
        preconditionFailure(
            "Release 빌드 전에 CAPLOG_API_BASE_URL을 운영 서버의 HTTPS 주소로 설정해야 합니다."
        )
        #endif
    }()

    static let apiPrefix = "/api"

    private static var configuredBaseURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "CAPLOG_API_BASE_URL") as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("$("),
              let url = URL(string: trimmed),
              url.host != nil,
              url.scheme == "http" || url.scheme == "https" else {
            return nil
        }
        return url
    }
}
