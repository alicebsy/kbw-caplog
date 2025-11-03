import Foundation

// MARK: - Friend
public struct Friend: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let avatarURL: URL?
    
    public init(id: String, name: String, avatarURL: URL?) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
    }
}

// MARK: - Chat (서버 요약 모델)
public struct ChatSummary: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let lastMessage: String
    public let updatedAt: Date
    public let unreadCount: Int
    public let avatarURL: URL?
}

// 서버 메시지 모델
public struct Message: Identifiable, Codable, Hashable {
    public let id: String
    public let chatId: String
    public let senderId: String
    public let senderName: String
    public let text: String
    public let createdAt: Date
}

// MARK: - Share
public struct Share: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let createdAt: Date?
    public let updatedAt: Date?
}

public struct ShareDetail: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let members: [ShareMember]
    public let screenshots: [ShareScreenshot]?
    public let createdAt: Date
}

public struct ShareMember: Identifiable, Codable, Hashable {
    public let id: String
    public let userId: String
    public let name: String
    public let role: String?
    public let avatarURL: URL?
}

public struct ShareScreenshot: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String?
    public let thumbnailURL: URL?
}

// MARK: - Comment
public struct Comment: Identifiable, Codable, Hashable {
    public let id: String
    public let shareId: String
    public let userId: String
    public let userName: String
    public let text: String
    public let createdAt: Date
}
