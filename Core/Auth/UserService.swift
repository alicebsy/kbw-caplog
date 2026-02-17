import Foundation

/// 사용자 프로필/인증 API
/// - GET /api/users/me: 프로필 조회
/// - PUT /api/users/me: 프로필 수정
/// - POST /api/auth/logout: 로그아웃
struct UserService {
    private let client = APIClient()
    /// Mock 사용 여부 (false: 실제 백엔드 연동)
    private let useMockData = false

    // MARK: - Profile

    /// 내 프로필 조회 (JWT Bearer 필요)
    /// - GET /api/users/me
    func fetchMe() async throws -> UserProfile {
        if useMockData {
            print("🔧 Mock: fetchMe() - UserDefaults에서 데이터 로드")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
            
            let defaults = UserDefaults.standard
            let userId = defaults.string(forKey: "userProfile_userId") ?? "ewhakbw"
            let nickname = defaults.string(forKey: "userProfile_nickname") ?? "강배우"
            let email = defaults.string(forKey: "userProfile_email") ?? "ewhakbw@gmail.com"
            let genderString = defaults.string(forKey: "userProfile_gender")
            let birthdayTimestamp = defaults.double(forKey: "userProfile_birthday")
            let birthday = birthdayTimestamp > 0 ? Date(timeIntervalSince1970: birthdayTimestamp) : nil
            
            print("📦 로드된 데이터:")
            print("   - nickname: \(nickname)")
            print("   - gender: \(genderString ?? "nil")")
            print("   - birthday timestamp: \(birthdayTimestamp)")
            print("   - birthday date: \(birthday?.description ?? "nil")")
            
            return UserProfile(
                userNo: nil,
                userId: userId,
                nickname: nickname,
                email: email,
                gender: genderString,
                birthday: birthday,
                avatarURL: nil
            )
        }
        
        return try await client.request("GET", path: Endpoints.me)
    }

    /// 프로필 수정 (JWT Bearer 필요)
    /// - PUT /api/users/me
    func updateMe(nickname: String, gender: MyPageViewModel.Gender?, birthday: Date?) async throws -> UserProfile {
        if useMockData {
            print("🔧 Mock: updateMe() - 프로필 업데이트 성공")
            print("   - nickname: \(nickname)")
            print("   - gender: \(gender?.rawValue ?? "nil")")
            print("   - birthday: \(birthday?.description ?? "nil")")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
            
            // UserDefaults에 저장
            let defaults = UserDefaults.standard
            defaults.set(nickname, forKey: "userProfile_nickname")
            defaults.set(gender?.apiCode, forKey: "userProfile_gender")
            if let birthday = birthday {
                let timestamp = birthday.timeIntervalSince1970
                defaults.set(timestamp, forKey: "userProfile_birthday")
                print("💾 생년월일 저장: \(birthday) → timestamp: \(timestamp)")
            } else {
                defaults.removeObject(forKey: "userProfile_birthday")
                print("💾 생년월일 삭제")
            }
            defaults.synchronize() // 즉시 저장
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            
            return UserProfile(
                userNo: nil,
                userId: "ewhakbw",
                nickname: nickname,
                email: "ewhakbw@gmail.com",
                gender: gender?.apiCode,
                birthday: birthday,
                avatarURL: nil
            )
        }
        
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        let body = UpdateUserProfileRequest(
            nickname: nickname,
            gender: gender?.apiCode,
            birthday: birthday.map { df.string(from: $0) },
            avatarURL: nil
        )
        return try await client.request("PUT", path: Endpoints.updateMe, body: body)
    }

    // MARK: - Auth

    /// 로그아웃 (선택적 refreshToken 전송)
    /// - POST /api/auth/logout
    func logout() async throws {
        if useMockData {
            print("🔧 Mock: logout() - 로그아웃 성공")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
            return
        }
        
        try await client.requestVoid("POST", path: Endpoints.logout)
    }

    /// 비밀번호 변경 (JWT Bearer 필요)
    /// - PUT /api/auth/password
    func changePassword(current: String, new: String) async throws {
        if useMockData {
            print("🔧 Mock: changePassword() - 비밀번호 변경 성공")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
            return
        }
        
        struct Payload: Encodable {
            let currentPassword: String
            let newPassword: String
        }
        let body = Payload(currentPassword: current, newPassword: new)
        try await client.requestVoid("PUT", path: Endpoints.changePassword, body: body, authorized: true)
    }
}
