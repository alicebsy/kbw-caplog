import Foundation

enum APIConfig {
    static var baseURL: URL {
        #if targetEnvironment(simulator)
        // 시뮬레이터에서는 localhost 사용
        return URL(string: "http://127.0.0.1:8080")!
        #else
        // 실기기에서는 맥북의 로컬 IP 사용
        // TODO: 현재 네트워크 환경의 맥북 IP로 변경 필요
        return URL(string: "http://192.168.0.14:8080")!
        #endif
    }
    
    static let apiPrefix = "/api"
}
