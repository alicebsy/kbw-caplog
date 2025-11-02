import Foundation

struct Friend: Identifiable, Codable {
    let id: String
    let name: String
    let status: String?
    let avatarURL: URL?
}

struct ChatSummary: Identifiable, Codable {
    let id: String
    let title: String
    let lastMessage: String
    let updatedAt: Date
    let unreadCount: Int
    let avatarURL: URL?
}

struct Message: Identifiable, Codable {
    let id: String
    let chatId: String
    let senderId: String
    let senderName: String
    let text: String
    let createdAt: Date
}
