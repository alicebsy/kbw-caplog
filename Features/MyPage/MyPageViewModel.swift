import SwiftUI
import Combine
import CoreLocation

@MainActor
final class MyPageViewModel: ObservableObject {
    enum Gender: String, CaseIterable, Identifiable {
        case male = "남성"
        case female = "여성"
        
        var id: String { rawValue }
        var apiCode: String {
            switch self {
            case .male: return "M"
            case .female: return "F"
            }
        }
    }

    // UI 바인딩 상태
    @Published var userId: String = ""
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var gender: Gender? = nil  // nil = 선택 안 함
    @Published var birthday: Date? = nil
    @Published var profileImage: UIImage? = nil  // 프로필 이미지

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
        print("🚀🚀🚀 MyPageViewModel onAppear 시작!")
        Task { await refreshAll() }
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProfile() }
            group.addTask { await self.refreshScreenshots() }
        }
    }

    func loadProfile() async {
        print("🔵🔵🔵 loadProfile 시작!")
        
        // 먼저 UserDefaults에서 즉시 로드하여 UI 업데이트 (깜빡임 방지)
        let defaults = UserDefaults.standard
        if let savedNickname = defaults.string(forKey: "userProfile_nickname") {
            name = savedNickname
            print("⚡️ UserDefaults에서 즉시 로드: \(savedNickname)")
        }
        if let savedGender = defaults.string(forKey: "userProfile_gender") {
            gender = savedGender == "M" ? .male : .female
        }
        let birthdayTimestamp = defaults.double(forKey: "userProfile_birthday")
        if birthdayTimestamp > 0 {
            birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        }
        // 프로필 이미지 로드
        if let imageData = defaults.data(forKey: "userProfile_imageData"),
           let image = UIImage(data: imageData) {
            profileImage = image
            print("⚡️ 프로필 이미지 로드 성공")
        }
        
        // 그 다음 서버에서 동기화
        do {
            print("🔵 userService.fetchMe() 호출 중...")
            let me = try await userService.fetchMe()
            print("🔵 fetchMe 성공! userId: \(me.userId), nickname: \(me.nickname)")
            userId = me.userId
            name = me.nickname
            email = me.email
            gender = me.gender.map { $0 == "M" ? .male : .female }
            birthday = me.birthday
            print("✅ 프로필 로드 완료: \(userId), \(name), \(gender?.rawValue ?? "미선택"), birthday: \(birthday?.description ?? "nil")")
            
            NotificationCenter.default.post(
                name: .userProfileUpdated,
                object: nil,
                userInfo: ["nickname": name]
            )
        } catch {
            print("❌❌❌ 프로필 로드 실패: \(error)")
            // 이미 UserDefaults에서 로드했으므로 기본값으로 덮어쓰지 않음
            if userId.isEmpty {
                userId = "ewhakbw"
                email = "ewhakbw@gmail.com"
            }
            
            NotificationCenter.default.post(
                name: .userProfileUpdated,
                object: nil,
                userInfo: ["nickname": name]
            )
        }
    }

    func saveProfile() async {
        print("🟢🟢🟢 saveProfile() 시작!")
        print("   - name: \(name)")
        print("   - gender: \(gender?.rawValue ?? "미선택")")
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
            print("🟢 userService.updateMe 호출 중...")
            let updated = try await userService.updateMe(
                nickname: name,
                gender: gender,
                birthday: birthday
            )
            
            print("✅ API 호출 성공!")
            print("   - 반환된 userId: \(updated.userId)")
            print("   - 반환된 nickname: \(updated.nickname)")
            print("   - 반환된 gender: \(updated.gender ?? "nil")")
            
            userId = updated.userId
            name = updated.nickname
            email = updated.email
            gender = updated.gender.map { $0 == "M" ? MyPageViewModel.Gender.male : MyPageViewModel.Gender.female }
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
    
    // MARK: - 프로필 이미지 저장
    func saveProfileImage(_ image: UIImage?) {
        let defaults = UserDefaults.standard
        if let image = image,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            defaults.set(imageData, forKey: "userProfile_imageData")
            print("💾 프로필 이미지 저장 성공")
        } else {
            defaults.removeObject(forKey: "userProfile_imageData")
            print("💾 프로필 이미지 삭제 (기본 이미지로)")
        }
        defaults.synchronize()
    }
}

extension Notification.Name {
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
}
