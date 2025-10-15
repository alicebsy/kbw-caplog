import Foundation

struct UserService {
    private let client = APIClient()

    // MARK: - Profile

    func fetchMe() async throws -> UserProfile {
        try await client.request("GET", path: Endpoints.me)
    }

    func updateMe(nickname: String, gender: MyPageViewModel.Gender?, birthday: Date?) async throws -> UserProfile {
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
        try await client.requestVoid("POST", path: Endpoints.logout)
    }

    /// ✅ 비밀번호 변경
    /// 서버 엔드포인트 예시: PUT /api/v1/auth/password
    /// Endpoints.changePassword 가 프로젝트에 정의되어 있어야 합니다.
    func changePassword(current: String, new: String) async throws {
        struct Payload: Encodable {
            let currentPassword: String
            let newPassword: String
        }
        let body = Payload(currentPassword: current, newPassword: new)
        try await client.requestVoid("PUT", path: Endpoints.changePassword, body: body)
    }
}
