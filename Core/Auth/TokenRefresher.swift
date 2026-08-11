import Foundation

/// 액세스 토큰 갱신을 단일 실행(single-flight)으로 직렬화합니다.
///
/// 서버는 `POST /api/auth/refresh`에서 리프레시 토큰도 함께 회전시키고 기존 토큰을
/// 폐기합니다. 따라서 여러 요청이 동시에 401을 받아 각자 갱신을 시도하면 두 번째부터는
/// "이미 폐기된 리프레시 토큰" 오류로 실패해 사용자가 로그아웃됩니다.
/// 이 actor는 갱신이 진행 중이면 뒤따르는 호출이 같은 작업을 기다리게 만듭니다.
actor TokenRefresher {
    static let shared = TokenRefresher()

    private var inFlight: Task<Bool, Never>?

    private init() {}

    /// 갱신을 시도하고 요청을 재시도할 수 있는지 반환합니다.
    /// - Parameter failedToken: 401을 받은 요청이 사용했던 액세스 토큰
    /// - Returns: 재시도 가능하면 `true`. `false`면 호출부가 세션을 정리해야 합니다.
    func refresh(failedToken: String?) async -> Bool {
        // 다른 요청이 이미 갱신을 끝냈다면 재시도만 하면 됩니다.
        if let failedToken,
           let current = SessionStore.readJWT(),
           current != failedToken {
            return true
        }

        // 진행 중인 갱신이 있으면 그 결과를 함께 기다립니다.
        if let inFlight {
            return await inFlight.value
        }

        let task = Task<Bool, Never> { await Self.performRefresh() }
        inFlight = task
        defer { inFlight = nil }
        return await task.value
    }

    private static func performRefresh() async -> Bool {
        guard let refreshToken = SessionStore.readRefreshToken(),
              !refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        do {
            let tokens = try await AuthAPI.refresh(refreshToken: refreshToken)
            // 회전된 리프레시 토큰까지 저장해야 다음 갱신이 성공합니다.
            SessionStore.save(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
            return true
        } catch {
            #if DEBUG
            print("⚠️ TokenRefresher: 토큰 갱신 실패 - \(error.localizedDescription)")
            #endif
            return false
        }
    }
}
