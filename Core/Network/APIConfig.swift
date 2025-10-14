import Foundation

enum APIConfig {
    // 스프링 부트 서버 베이스 URL
    static let baseURL = URL(string: "http://localhost:8080")!
    // 일단 로컬로
    static let apiPrefix = "/api"
}
