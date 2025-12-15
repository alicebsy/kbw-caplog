import Foundation

// MARK: - FriendAPI
struct FriendAPI {
    private let client: APIClient
    
    init(client: APIClient = APIClient()) {
        self.client = client
    }
    
    /// 친구 추가
    func add(userId: String) async throws -> Friend {
        struct AddFriendBody: Encodable {
            let userId: String
        }
        return try await client.request(
            "POST",
            path: Endpoints.friendList,
            body: AddFriendBody(userId: userId)
        )
    }
    
    /// 친구 목록 조회
    func list() async throws -> [Friend] {
        try await client.request("GET", path: Endpoints.friendList)
    }
    
    /// 친구 삭제
    func delete(userId: String) async throws {
        try await client.requestVoid("DELETE", path: "/friends/\(userId)")
    }
}
