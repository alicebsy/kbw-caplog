import Foundation

// MARK: - AlertAPI
enum AlertAPI {
static let baseURL = AuthAPI.baseURL

static func expiringAlerts() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("alerts/expiring"))
req.httpMethod = "GET"
return req
}
}
