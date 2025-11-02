import Foundation

/// 백엔드 API 엔드포인트 정리
enum Endpoints {

    // MARK: - Auth (인증)
    static let login            = "/auth/login"
    static let logout           = "/auth/logout"
    static let refreshToken     = "/auth/refresh"
    static let changePassword   = "/api/v1/auth/password"

    // MARK: - User (유저)
    static let me               = "/users/me"
    static let updateMe         = "/users/me"
    static let deleteMe         = "/users/me"
    static let userProfile      = "/users/profile"
    static let friendList       = "/users/friends"
    static let shareFriends     = "/users/friends"

    // MARK: - Screenshot
    static let screenshots      = "/screenshots"
    static let screenshotById   = "/screenshots/{id}"
    static let uploadScreenshot = "/screenshots/upload"
    static let metadata         = "/screenshots/metadata"

    // MARK: - Folder
    static let folders          = "/folders"
    static let folderById       = "/folders/{id}"
    static let folderItems      = "/folders/{id}/items"

    // MARK: - Share
    static let shares           = "/shares"
    static func shareDetail(_ id: String) -> String { "/shares/\(id)" }
    static func shareMembers(_ id: String) -> String { "/shares/\(id)/members" }
    static func shareMember(_ sid: String, _ uid: String) -> String { "/shares/\(sid)/members/\(uid)" }
    static func shareComments(_ id: String) -> String { "/shares/\(id)/comments" }
    static func shareComment(_ sid: String, _ cid: String) -> String { "/shares/\(sid)/comments/\(cid)" }

    // MARK: - 채팅/메시지
    static let shareChats       = "/share/chats"
    static func messages(chatId: String) -> String { "/share/chats/\(chatId)/messages" }
    static func sendMessage(chatId: String) -> String { "/share/chats/\(chatId)/messages" }
    /// ✅ 읽음 처리 엔드포인트 추가
    static func chatRead(chatId: String) -> String { "/share/chats/\(chatId)/read" }

    // MARK: - Search
    static let search            = "/search"
    static let searchScreenshots = "/search/screenshots"
    static let searchRecent      = "/search/recent"

    // MARK: - Notification
    static let alerts           = "/alerts"
    static let notifications    = "/notifications"

    // MARK: - Misc
    static let healthCheck      = "/health"
    static let version          = "/version"
}
