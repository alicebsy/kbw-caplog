//
//  Endpoints.swift
//  KBW-CAPLOG
//
//  Created by Minha on 2025/11/03.
//

import Foundation

/// 백엔드 API 엔드포인트 정리
/// - 각 도메인별로 grouping (Auth / User / Screenshot / Folder / Search / Share 등)
/// - 실제 요청 시 `APIClient` 내부에서 `APIConfig.baseURL + Endpoints.xxx`로 결합됨
enum Endpoints {

    // MARK: - Auth (인증 관련)
    static let login            = "/auth/login"              // POST
    static let logout           = "/auth/logout"             // POST
    static let refreshToken     = "/auth/refresh"            // POST
    static let changePassword   = "/api/v1/auth/password"    // PUT

    // MARK: - User (유저 정보)
    static let me               = "/users/me"                // GET
    static let updateMe         = "/users/me"                // PUT
    static let deleteMe         = "/users/me"                // DELETE
    static let userProfile      = "/users/profile"           // GET
    static let friendList       = "/users/friends"           // GET   (기존 친구 목록)
    // Share 모듈에서 재사용하기 쉽게 alias 추가
    static let shareFriends     = "/users/friends"           // GET   (friends API alias)

    // MARK: - Screenshot (스크린샷 관련)
    static let screenshots      = "/screenshots"             // GET ?cursor=&size=
    static let screenshotById   = "/screenshots/{id}"        // GET / DELETE
    static let uploadScreenshot = "/screenshots/upload"      // POST (멀티파트)
    static let metadata         = "/screenshots/metadata"    // GET

    // MARK: - Folder (폴더 및 분류)
    static let folders          = "/folders"                 // GET / POST
    static let folderById       = "/folders/{id}"            // GET / PUT / DELETE
    static let folderItems      = "/folders/{id}/items"      // GET

    // MARK: - Share (공유)
    static let share            = "/share"                   // POST (링크 생성)
    static let sharedItems      = "/share/items"             // GET (공유 받은 항목)
    static let unshare          = "/share/{id}"              // DELETE

    // ====== 👇 채팅/메시지 (Share 탭 내 채팅) ======
    static let shareChats       = "/share/chats"             // GET: 채팅 목록
    static func messages(chatId: String) -> String {
        "/share/chats/\(chatId)/messages"                   // GET: 메시지 목록
    }
    static func sendMessage(chatId: String) -> String {
        "/share/chats/\(chatId)/messages"                   // POST: 메시지 전송
    }
    // ==============================================

    // MARK: - Search (검색)
    /// GPT 분류 결과 / 폴더 대·소분류 기반 검색
    static let search           = "/api/v1/search"           // POST
    /// 자동완성 / 추천 키워드 (옵션)
    static let suggest          = "/api/v1/search/suggest"   // GET ?q=

    // MARK: - Alert / Notification
    static let alerts           = "/alerts"                  // GET / PATCH(read)
    static let notifications    = "/notifications"           // GET / DELETE

    // MARK: - Misc / ETC
    static let healthCheck      = "/health"                  // GET
    static let version          = "/version"                 // GET
}
