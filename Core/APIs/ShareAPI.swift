import Foundation

// MARK: - ShareAPI
enum ShareAPI {
static let baseURL = AuthAPI.baseURL

static func create() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("shares"))
req.httpMethod = "POST"
return req
}

static func list() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("shares"))
req.httpMethod = "GET"
return req
}

static func detail(shareId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("shares/\(shareId)"))
req.httpMethod = "GET"
return req
}

static func inviteMember(shareId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("shares/\(shareId)/members"))
req.httpMethod = "POST"
return req
}

static func removeMember(shareId: String, userId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("shares/\(shareId)/members/\(userId)"))
req.httpMethod = "DELETE"
return req
}

static func postComment(shareId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("shares/\(shareId)/comments"))
req.httpMethod = "POST"
return req
}

static func getComments(shareId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("shares/\(shareId)/comments"))
req.httpMethod = "GET"
return req
}

static func deleteComment(shareId: String, commentId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("shares/\(shareId)/comments/\(commentId)"))
req.httpMethod = "DELETE"
return req
}
}
