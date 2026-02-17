import Foundation
import Combine

struct UserProfile: Codable {
    /// DB PK (스크린샷 업로드 등 API에서 사용)
    var userNo: Int?
    var userId: String       // 아이디 (로그인 ID)
    var nickname: String
    var email: String
    var gender: String?      // "M" or "F"
    var birthday: Date?      // 백엔드 LocalDate → "yyyy-MM-dd" 문자열
    var avatarURL: String?   // 프로필 이미지 URL

    enum CodingKeys: String, CodingKey {
        case userNo, userId, nickname, email, gender, birthday
        case avatarURL = "avatar_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userNo = try c.decodeIfPresent(Int.self, forKey: .userNo)
        userId = try c.decodeIfPresent(String.self, forKey: .userId) ?? ""
        nickname = try c.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        gender = try c.decodeIfPresent(String.self, forKey: .gender)
        avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL)
        birthday = try Self.decodeBirthday(c)
    }

    private static let birthdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func decodeBirthday(_ c: KeyedDecodingContainer<CodingKeys>) throws -> Date? {
        guard let str = try c.decodeIfPresent(String.self, forKey: .birthday) else { return nil }
        return birthdayFormatter.date(from: str)
    }

    init(userNo: Int?, userId: String, nickname: String, email: String, gender: String?, birthday: Date?, avatarURL: String?) {
        self.userNo = userNo
        self.userId = userId
        self.nickname = nickname
        self.email = email
        self.gender = gender
        self.birthday = birthday
        self.avatarURL = avatarURL
    }
}

struct UpdateUserProfileRequest: Encodable {
    let nickname: String
    let gender: String?
    let birthday: String? // yyyy-MM-dd
    let avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case nickname, gender, birthday
        case avatarURL = "avatar_url"
    }
}
