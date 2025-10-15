import Foundation

// MARK: - FolderAPI
enum FolderAPI {
static let baseURL = AuthAPI.baseURL

static func create() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("folders"))
req.httpMethod = "POST"
return req
}

static func list() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("folders"))
req.httpMethod = "GET"
return req
}

static func detail(folderId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("folders/\(folderId)"))
req.httpMethod = "GET"
return req
}

static func update(folderId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("folders/\(folderId)"))
req.httpMethod = "PATCH"
return req
}

static func delete(folderId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("folders/\(folderId)"))
req.httpMethod = "DELETE"
return req
}

static func addScreenshot(folderId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("folders/\(folderId)/screenshots"))
req.httpMethod = "POST"
return req
}

static func removeScreenshot(folderId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("folders/\(folderId)/screenshots"))
req.httpMethod = "DELETE"
return req
}
}
