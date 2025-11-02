import Foundation

// MARK: - Friend
struct Friend: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let status: String?
    let avatarURL: URL?
}

// MARK: - Chat
struct ChatSummary: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let lastMessage: String
    let updatedAt: Date
    let unreadCount: Int
    let avatarURL: URL?
}

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let chatId: String
    let senderId: String
    let senderName: String
    let text: String
    let createdAt: Date
}

// MARK: - Share
struct Share: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let createdAt: Date?
    let updatedAt: Date?
}

struct ShareDetail: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let members: [ShareMember]
    let screenshots: [ShareScreenshot]?
    let createdAt: Date
}

struct ShareMember: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let name: String
    let role: String?
    let avatarURL: URL?
}

struct ShareScreenshot: Identifiable, Codable, Hashable {
    let id: String
    let title: String?
    let thumbnailURL: URL?
}

// MARK: - Comment
struct Comment: Identifiable, Codable, Hashable {
    let id: String
    let shareId: String
    let userId: String
    let userName: String
    let text: String
    let createdAt: Date
}
