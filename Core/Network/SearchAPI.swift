import Foundation

// MARK: - Protocol
protocol SearchAPIType {
    func search(_ query: SearchQueryDTO) async throws -> SearchResponse
    func searchScreenshots(query: String?) async throws -> SearchResponse
    func recentSearches() async throws -> [String]
}

// MARK: - SearchAPI
struct SearchAPI: SearchAPIType {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    /// 검색 수행 (POST 방식)
    func search(_ query: SearchQueryDTO) async throws -> SearchResponse {
        try await client.request(
            "POST",
            path: Endpoints.search,
            body: query
        )
    }

    /// 스크린샷 검색 (GET 방식)
    func searchScreenshots(query: String? = nil) async throws -> SearchResponse {
        var queryItems: [URLQueryItem]? = nil
        if let query = query {
            queryItems = [URLQueryItem(name: "q", value: query)]
        }

        return try await client.request(
            "GET",
            path: Endpoints.searchScreenshots,
            query: queryItems
        )
    }

    /// 최근 검색 기록
    func recentSearches() async throws -> [String] {
        struct RecentSearchResponse: Decodable { let queries: [String] }
        let response: RecentSearchResponse = try await client.request(
            "GET",
            path: Endpoints.searchRecent
        )
        return response.queries
    }
}
