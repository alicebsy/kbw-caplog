import SwiftUI
import Combine

@MainActor
final class MyPageViewModel: ObservableObject {
    enum Gender: String, CaseIterable, Identifiable { case male = "남성", female = "여성"; var id: String { rawValue } }

    // UI 바인딩 상태
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var gender: Gender = .male
    @Published var birthday: Date? = nil

    @Published var allowLocationRecommend = true
    @Published var allowNotification = true

    @Published var savedCount: Int = 0
    @Published var recommendedCount: Int = 0

    // 스크린샷 목록
    @Published var screenshots: [ScreenshotItem] = []
    @Published var nextCursor: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let userService = UserService()
    private let screenshotService = ScreenshotService()

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
            birthday = me.birthday
            // 통계치가 따로 오면 사용, 예시는 스크린샷 개수에서 유추
        } catch { errorMessage = error.localizedDescription }
    }

    func saveProfile() async {
        do {
            let updated = try await userService.updateMe(nickname: name, gender: gender, birthday: birthday)
            name = updated.nickname
            email = updated.email
        } catch { errorMessage = error.localizedDescription }
    }

    func logout() async {
        do {
            try await userService.logout()
            AuthStorage.shared.clear()
            // TODO: 루트 전환이 필요하면 여기서 AppState와 연동
        } catch { errorMessage = error.localizedDescription }
    }

    func refreshScreenshots() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await screenshotService.fetchMyScreenshots(cursor: nil)
            screenshots = page.items
            nextCursor = page.nextCursor
            savedCount = page.items.count // 예시
        } catch { errorMessage = error.localizedDescription }
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
        } catch { errorMessage = error.localizedDescription }
    }
}
