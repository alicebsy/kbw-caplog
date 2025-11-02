import Foundation

final class ShareAPI {
    private let client = APIClient.shared

    func fetchFriends() async throws -> [Friend] {
        try await client.request(Endpoints.shareFriends, method: .get, as: [Friend].self)
    }

    func fetchChats() async throws -> [ChatSummary] {
        try await client.request(Endpoints.shareChats, method: .get, as: [ChatSummary].self)
    }

    func fetchMessages(chatId: String) async throws -> [Message] {
        try await client.request(Endpoints.messages(chatId: chatId), method: .get, as: [Message].self)
    }

    func sendMessage(chatId: String, text: String) async throws -> Message {
        let body = ["text": text]
        return try await client.request(Endpoints.sendMessage(chatId: chatId), method: .post, body: body, as: Message.self)
    }
}
