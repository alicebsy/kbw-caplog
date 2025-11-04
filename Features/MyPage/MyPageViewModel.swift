import SwiftUI
import Combine
import CoreLocation

@MainActor
final class MyPageViewModel: ObservableObject {
    enum Gender: String, CaseIterable, Identifiable {
        case male = "남성", female = "여성"
        var id: String { rawValue }
        var apiCode: String { self == .male ? "M" : "F" }
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
    
    private let locationPermission = LocationPermission()
    private let notificationPermission = NotificationPermission()
    private var cancellables = Set<AnyCancellable>()

    init() {
        locationPermission.$status
            .map { $0 == .authorizedWhenInUse || $0 == .authorizedAlways }
            .assign(to: &$allowLocationRecommend)
        
        notificationPermission.$status
            .map { $0 == .authorized }
            .assign(to: &$allowNotification)
    }

    var displayName: String { name }
    var isNameValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var isBirthdayValid: Bool {
        guard let b = birthday else { return true }
        return b <= Date()
    }

    var canSaveProfile: Bool {
        isNameValid && isBirthdayValid && !isLoading
    }

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
            birthday = me.birthday
        } catch {
            // Mock 데이터 (API 연결 전)
            name = "강배우"
            email = "ewhakbw@gmail.com"
            gender = .male
            birthday = nil
        }
    }

    func saveProfile() async {
        guard isNameValid else {
            errorMessage = "이름을 입력해주세요."
            return
        }
        guard isBirthdayValid else {
            errorMessage = "생년월일이 올바르지 않습니다."
            return
        }
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }
        
        do {
            let updated = try await userService.updateMe(
                nickname: name,
                gender: gender,
                birthday: birthday
            )
            name = updated.nickname
            email = updated.email

            // ✅ 수정: 성공 시 팝업 메시지 표시
            errorMessage = "프로필이 저장되었습니다."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        do {
            try await userService.logout()
            AuthStorage.shared.clear()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - 권한 관리
    func toggleLocationPermission(_ newValue: Bool) {
        if newValue {
            locationPermission.request()
        } else {
            locationPermission.openSettings()
        }
    }
    
    func toggleNotificationPermission(_ newValue: Bool) {
        if newValue {
            notificationPermission.request()
        } else {
            notificationPermission.openSettings()
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
