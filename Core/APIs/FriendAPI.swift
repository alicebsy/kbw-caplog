import Foundation

// MARK: - FriendAPI
enum FriendAPI {
static let baseURL = AuthAPI.baseURL

static func add() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("friends"))
req.httpMethod = "POST"
return req
}

static func list() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("friends"))
req.httpMethod = "GET"
return req
}

static func delete(userId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("friends/\(userId)"))
req.httpMethod = "DELETE"
return req
}
}
