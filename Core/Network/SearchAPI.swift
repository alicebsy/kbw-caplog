import Foundation

protocol SearchAPIType {
    func search(_ body: SearchQueryDTO) async throws -> SearchResponse
}

struct SearchAPI: SearchAPIType {
    private let client: APIClient
    init(client: APIClient = .shared) { self.client = client }

    func search(_ body: SearchQueryDTO) async throws -> SearchResponse {
        let req = APIRequest(
            method: .post,
            path: Endpoints.search,   // ← Endpoints에 상수만 추가하면 됨(아래 수정 항목 참조)
            headers: ["Content-Type":"application/json"],
            body: body
        )
        return try await client.perform(req, as: SearchResponse.self)
    }
}
