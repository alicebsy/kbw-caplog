import Foundation

enum Endpoints {
    // 유저
    static let me         = "/users/me"           // GET
    static let updateMe   = "/users/me"           // PUT
    static let logout     = "/auth/logout"        // POST

    // 스크린샷
    static let screenshots = "/screenshots"       // GET ?cursor=&size=
    
    static let changePassword = "/api/v1/auth/password"
}
