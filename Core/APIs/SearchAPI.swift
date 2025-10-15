import Foundation

// MARK: - SearchAPI
enum SearchAPI {
static let baseURL = AuthAPI.baseURL

static func searchScreenshot() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("search/screenshots"))
req.httpMethod = "GET"
return req
}

static func recentSearches() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("search/recent"))
req.httpMethod = "GET"
return req
}
}
