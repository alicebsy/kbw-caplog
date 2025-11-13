import Foundation

// MARK: - Friend
public struct Friend: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let avatarURL: URL?
    
    // ✅ 추가: 로컬 Asset 이미지 이름 (서버에서 오지 않는 필드)
    public var profileImage: String?
    
    public init(id: String, name: String, avatarURL: URL?, profileImage: String? = nil) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
        self.profileImage = profileImage
    }
    
    // ✅ Codable을 위한 CodingKeys (profileImage는 서버 응답에 없으므로 제외)
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarURL = "avatar_url"
        // profileImage는 로컬 전용이므로 인코딩/디코딩에서 제외
    }
    
    // ✅ 커스텀 디코더 (서버 응답 파싱용)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
        profileImage = nil // 서버에서 오지 않으므로 nil로 초기화
    }
    
    // ✅ 커스텀 인코더 (서버 전송용)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        // profileImage는 서버로 보내지 않음
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
