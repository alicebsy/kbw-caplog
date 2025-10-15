import Foundation

enum APIConfig {
    /// 시뮬레이터면 127.0.0.1 사용
    static let baseURL = URL(string: "http://192.168.200.134:8080")!
    // 실기기라면 맥북의 로컬 IP로 교체: "http://192.168.x.x:8080"
    // 일단 로컬로
    static let apiPrefix = "/api"
}
