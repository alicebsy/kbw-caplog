import Foundation
import Combine

struct UserProfile: Codable {
    var userId: String       // 아이디 (로그인 ID)
    var nickname: String
    var email: String
    var gender: String?      // "M" or "F"
    var birthday: Date?      // ISO-8601 (스프링 @JsonFormat 권장)

    enum CodingKeys: String, CodingKey {
        case userId, nickname, email, gender, birthday
    }
}

struct UpdateUserProfileRequest: Encodable {
    let nickname: String
    let gender: String?
    let birthday: String? // yyyy-MM-dd
}
