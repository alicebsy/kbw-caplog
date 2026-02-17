//
//  ScreenshotService.swift
//  caplog
//
//  내 스크린샷 목록 조회 (GET /api/screenshots, JWT Bearer 필요)
//

import Foundation

struct ScreenshotService {
    private let client = APIClient()

    func fetchMyScreenshots(cursor: String? = nil, size: Int = 20) async throws -> PagedResponse<ScreenshotItem> {
        let query = [
            cursor.map { URLQueryItem(name: "cursor", value: $0) },
            URLQueryItem(name: "size", value: "\(size)")
        ].compactMap { $0 }

        return try await client.request("GET", path: Endpoints.screenshots, query: query)
    }
}
