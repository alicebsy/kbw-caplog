import Foundation

// MARK: - MetadataAPI
enum MetadataAPI {
static let baseURL = AuthAPI.baseURL

static func add(screenshotId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots/\(screenshotId)/metadata"))
req.httpMethod = "POST"
return req
}

static func list(screenshotId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots/\(screenshotId)/metadata"))
req.httpMethod = "GET"
return req
}

static func update(screenshotId: String, metadataId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots/\(screenshotId)/metadata/\(metadataId)"))
req.httpMethod = "PATCH"
return req
}

static func delete(screenshotId: String, metadataId: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots/\(screenshotId)/metadata/\(metadataId)"))
req.httpMethod = "DELETE"
return req
}
}
