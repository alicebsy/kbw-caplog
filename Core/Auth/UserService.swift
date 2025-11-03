import Foundation

struct UserService {
    private let client = APIClient()
    
    // ✅ Mock 모드 스위치 (개발 중에는 true로 설정)
    private let useMockData = true  // 서버 연결 전까지 true로 유지

    // MARK: - Profile

    func fetchMe() async throws -> UserProfile {
        // ✅ Mock 모드일 때 더미 데이터 반환
        if useMockData {
            print("🔧 Mock: fetchMe() - 더미 데이터 반환")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
            return UserProfile(
                nickname: "강배우",
                email: "ewhakbw@gmail.com",
                gender: "M",
                birthday: nil
            )
        }
        
        return try await client.request("GET", path: Endpoints.me)
    }

    func updateMe(nickname: String, gender: MyPageViewModel.Gender?, birthday: Date?) async throws -> UserProfile {
        // ✅ Mock 모드일 때 입력값 그대로 반환
        if useMockData {
            print("🔧 Mock: updateMe() - 프로필 업데이트 성공")
            print("   - nickname: \(nickname)")
            print("   - gender: \(gender?.rawValue ?? "nil")")
            print("   - birthday: \(birthday?.description ?? "nil")")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            
            return UserProfile(
                nickname: nickname,
                email: "ewhakbw@gmail.com",
                gender: gender.map { $0 == .male ? "M" : "F" },
                birthday: birthday
            )
        }
        
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        let body = UpdateUserProfileRequest(
            nickname: nickname,
            gender: gender.map { $0 == .male ? "M" : "F" },
            birthday: birthday.map { df.string(from: $0) }
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
