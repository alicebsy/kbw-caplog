import Foundation

// MARK: - ScreenshotAPI
enum ScreenshotAPI {
static let baseURL = AuthAPI.baseURL

static func upload(imageData: Data) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots"))
req.httpMethod = "POST"
// 이미지 multipart 업로드 구현 예정
return req
}

static func list() -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots"))
req.httpMethod = "GET"
return req
}

static func detail(id: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots/\(id)"))
req.httpMethod = "GET"
return req
}

static func delete(id: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots/\(id)"))
req.httpMethod = "DELETE"
return req
}

static func analyze(id: String) -> URLRequest {
var req = URLRequest(url: baseURL.appendingPathComponent("screenshots/\(id)/analyze"))
req.httpMethod = "POST"
return req
}
}
