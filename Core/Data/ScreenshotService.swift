//
//  ScreenshotService.swift
//  caplog
//
//  Created by user on 10/13/25.
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
