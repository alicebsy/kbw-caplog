import Foundation

// MARK: - ShareAPI
struct ShareAPI {
    private let client: APIClient
    
    init(client: APIClient = APIClient()) {
        self.client = client
    }
    
    // MARK: - 친구 관리
    
    /// 친구 목록 조회
    func fetchFriends() async throws -> [Friend] {
        try await client.request("GET", path: Endpoints.shareFriends)
    }
    
    // MARK: - 채팅
    
    /// 채팅방 목록 조회
    func fetchChats() async throws -> [ChatSummary] {
        try await client.request("GET", path: Endpoints.shareChats)
    }
    
    /// 특정 채팅방의 메시지 조회
    func fetchMessages(chatId: String) async throws -> [Message] {
        try await client.request("GET", path: Endpoints.messages(chatId: chatId))
    }
    
    /// 메시지 전송
    func sendMessage(chatId: String, text: String) async throws -> Message {
        struct SendMessageBody: Encodable {
            let text: String
        }
        return try await client.request(
            "POST",
            path: Endpoints.sendMessage(chatId: chatId),
            body: SendMessageBody(text: text)
        )
    }
    
    /// ✅ 채팅 읽음 처리 추가
    func markRead(chatId: String) async throws {
        try await client.requestVoid(
            "PATCH",
            path: Endpoints.chatRead(chatId: chatId)
        )
    }
    
    // MARK: - 공유 관리
    
    /// 공유 생성
    func createShare(title: String, screenshotIds: [String]) async throws -> Share {
        struct CreateShareRequest: Encodable {
            let title: String
            let screenshotIds: [String]
        }
        return try await client.request(
            "POST",
            path: Endpoints.shares,
            body: CreateShareRequest(title: title, screenshotIds: screenshotIds)
        )
    }
    
    /// 공유 목록 조회
    func listShares() async throws -> [Share] {
        try await client.request("GET", path: Endpoints.shares)
    }
    
    /// 공유 상세 조회
    func getShareDetail(shareId: String) async throws -> ShareDetail {
        try await client.request("GET", path: Endpoints.shareDetail(shareId))
    }
    
    /// 멤버 초대
    func inviteMember(shareId: String, userId: String) async throws -> ShareMember {
        struct InviteBody: Encodable {
            let userId: String
        }
        return try await client.request(
            "POST",
            path: Endpoints.shareMembers(shareId),
            body: InviteBody(userId: userId)
        )
    }
    
    /// 멤버 제거
    func removeMember(shareId: String, userId: String) async throws {
        try await client.requestVoid(
            "DELETE",
            path: Endpoints.shareMember(shareId, userId)
        )
    }
    
    // MARK: - 댓글
    
    /// 댓글 조회
    func getComments(shareId: String) async throws -> [Comment] {
        try await client.request("GET", path: Endpoints.shareComments(shareId))
    }
    
    /// 댓글 작성
    func postComment(shareId: String, text: String) async throws -> Comment {
        struct CommentBody: Encodable {
            let text: String
        }
        return try await client.request(
            "POST",
            path: Endpoints.shareComments(shareId),
            body: CommentBody(text: text)
        )
    }
    
    /// 댓글 삭제
    func deleteComment(shareId: String, commentId: String) async throws {
        try await client.requestVoid(
            "DELETE",
            path: Endpoints.shareComment(shareId, commentId)
        )
    }
}
