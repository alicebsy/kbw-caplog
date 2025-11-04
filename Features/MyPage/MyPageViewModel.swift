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
    @Published var successMessage: String? = nil

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
            print("✅ 프로필 로드 완료: \(name), \(gender.rawValue)")
            
            NotificationCenter.default.post(
                name: .userProfileUpdated,
                object: nil,
                userInfo: ["nickname": name]
            )
        } catch {
            print("⚠️ 프로필 로드 실패 (Mock 모드): \(error)")
            name = "강배우"
            email = "ewhakbw@gmail.com"
            gender = .male
            birthday = nil
            
            NotificationCenter.default.post(
                name: .userProfileUpdated,
                object: nil,
                userInfo: ["nickname": name]
            )
        }
    }

    func saveProfile() async {
        print("🔥 saveProfile() 시작")
        print("   - name: \(name)")
        print("   - gender: \(gender.rawValue)")
        print("   - birthday: \(birthday?.description ?? "nil")")
        
        guard isNameValid else {
            print("❌ 이름이 비어있음")
            errorMessage = "이름을 입력해주세요."
            return
        }
        guard isBirthdayValid else {
            print("❌ 생년월일이 올바르지 않음")
            errorMessage = "생년월일이 올바르지 않습니다."
            return
        }
        guard !isLoading else {
            print("❌ 이미 로딩 중")
            return
        }

        isLoading = true
        print("⏳ 저장 시작...")
        
        do {
            let updated = try await userService.updateMe(
                nickname: name,
                gender: gender,
                birthday: birthday
            )
            
            print("✅ API 호출 성공!")
            print("   - 반환된 nickname: \(updated.nickname)")
            print("   - 반환된 gender: \(updated.gender ?? "nil")")
            
            name = updated.nickname
            email = updated.email
            if let g = updated.gender {
                gender = (g == "M") ? .male : .female
            }
            birthday = updated.birthday
            
            print("✅ 상태 업데이트 완료")
            
            await MainActor.run {
                self.successMessage = "프로필이 저장되었습니다."
                print("✅ successMessage 설정됨: '\(self.successMessage ?? "")'")
            }
            
            NotificationCenter.default.post(
                name: .userProfileUpdated,
                object: nil,
                userInfo: ["nickname": name]
            )
            
        } catch {
            print("❌ API 호출 실패: \(error)")
            
            await MainActor.run {
                self.successMessage = "프로필이 저장되었습니다."
                print("✅ (Mock) successMessage 설정됨: '\(self.successMessage ?? "")'")
            }
            
            NotificationCenter.default.post(
                name: .userProfileUpdated,
                object: nil,
                userInfo: ["nickname": name]
            )
        }
        
        isLoading = false
        print("✅ saveProfile() 완료")
    }

    func logout() async {
        do {
            try await userService.logout()
            AuthStorage.shared.clear()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
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

extension Notification.Name {
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
}
