import Foundation

struct UserService {
    private let client = APIClient()
    
    // ✅ Mock 모드 스위치 (개발 중에는 true로 설정)
    private let useMockData = true  // 서버 연결 전까지 true로 유지

    // MARK: - Profile

    func fetchMe() async throws -> UserProfile {
        // ✅ Mock 모드일 때 UserDefaults에서 저장된 데이터 로드
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

    func updateMe(nickname: String, gender: MyPageViewModel.Gender?, birthday: Date?) async throws -> UserProfile {
        // ✅ Mock 모드일 때 UserDefaults에 저장
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

    func logout() async throws {
        // ✅ Mock 모드일 때 성공 처리
        if useMockData {
            print("🔧 Mock: logout() - 로그아웃 성공")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
            return
        }
        
        try await client.requestVoid("POST", path: Endpoints.logout)
    }

    /// ✅ 비밀번호 변경
    /// 서버 엔드포인트 예시: PUT /api/v1/auth/password
    /// Endpoints.changePassword 가 프로젝트에 정의되어 있어야 합니다.
    func changePassword(current: String, new: String) async throws {
        // ✅ Mock 모드일 때 성공 처리
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
        try await client.requestVoid("PUT", path: Endpoints.changePassword, body: body)
    }
}
