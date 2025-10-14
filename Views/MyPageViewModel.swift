import SwiftUI
import Combine

@MainActor
final class MyPageViewModel: ObservableObject {
    enum Gender: String, CaseIterable, Identifiable {
        case male = "남성", female = "여성"
        var id: String { rawValue }
        var apiCode: String { self == .male ? "M" : "F" } // ✅ 백엔드 코드 매핑
    }

    // UI 바인딩 상태
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var gender: Gender = .male
    @Published var birthday: Date? = nil

    @Published var allowLocationRecommend = true
    @Published var allowNotification = true

    @Published var savedCount: Int = 0
    @Published var recommendedCount: Int = 0

    // 리스트/에러 상태
    @Published var screenshots: [ScreenshotItem] = []
    @Published var nextCursor: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let userService = UserService()
    private let screenshotService = ScreenshotService()

    // Header 호환용
    var displayName: String { name }

    // ✅ 유효성 검사
    var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isEmailValid: Bool {
        // RFC 완벽 검증은 과하지만, 일반적인 패턴 검증
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    var isBirthdayValid: Bool {
        // 생일이 미래이면 안 됨
        guard let b = birthday else { return true }
        return b <= Date()
    }

    // ✅ 저장 버튼 활성 조건
    var canSaveProfile: Bool {
        isNameValid && isEmailValid && isBirthdayValid && !isLoading
    }

    // ✅ 백엔드 전송용 날짜 포맷 (yyyy-MM-dd)
    var birthdayYMDString: String? {
        guard let b = birthday else { return nil }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: b)
    }

    func onAppear() {
        Task { await refreshAll() }
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProfile() }
            group.addTask { await self.refreshScreenshots() }
        }
    }

    func loadProfile() async {
        do {
            let me = try await userService.fetchMe()
            name = me.nickname
            email = me.email
            if let g = me.gender { gender = (g == "M") ? .male : .female }
            birthday = me.birthday    // 서버가 Date로 내려주면 그대로, 문자열이면 디코더에서 처리
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile() async {
        guard canSaveProfile else {
            errorMessage = "입력값을 확인해주세요. (닉네임/이메일/생년월일)"
            return
        }
        do {
            // 백엔드 규격에 따라 Date? 또는 String?로 전송
            // 예: 서버가 yyyy-MM-dd 문자열을 받는다면 birthdayYMDString 사용
            let updated = try await userService.updateMe(
                nickname: name,
                gender: gender,
                birthday: birthday // 필요 시 birthdayYMDString로 바꿔주세요.
            )
            name = updated.nickname
            email = updated.email
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        do {
            try await userService.logout()
            AuthStorage.shared.clear()
            // TODO: 루트 전환이 필요하면 AppState와 연동
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshScreenshots() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await screenshotService.fetchMyScreenshots(cursor: nil)
            screenshots = page.items
            nextCursor = page.nextCursor
            savedCount = page.items.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMoreIfNeeded(current item: ScreenshotItem) async {
        guard let last = screenshots.last, last.id == item.id,
              let cursor = nextCursor, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await screenshotService.fetchMyScreenshots(cursor: cursor)
            screenshots.append(contentsOf: page.items)
            nextCursor = page.nextCursor
            savedCount = screenshots.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
