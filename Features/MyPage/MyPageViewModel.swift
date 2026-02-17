import SwiftUI
import Combine
import CoreLocation

/// 마이페이지 VM: 프로필·스크린샷 목록 모두 DB(서버) 연동
/// - 프로필: GET/PUT /api/users/me
/// - 스크린샷: GET /api/screenshots (screenshot_file 테이블)
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
        Task { await refreshAll() }
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProfile() }
            group.addTask { await self.refreshScreenshots() }
        }
    }

    /// 프로필 로드: DB(서버) 우선, 성공 시 캐시 갱신. 실패 시 기존 캐시만 표시 (mock 기본값 없음)
    func loadProfile() async {
        let defaults = UserDefaults.standard
        // 깜빡임 방지: 캐시된 값으로 먼저 표시
        if let savedNickname = defaults.string(forKey: "userProfile_nickname") { name = savedNickname }
        if let savedUserId = defaults.string(forKey: "userProfile_userId") { userId = savedUserId }
        if let savedEmail = defaults.string(forKey: "userProfile_email") { email = savedEmail }
        if let savedGender = defaults.string(forKey: "userProfile_gender") {
            gender = savedGender == "M" ? .male : .female
        }
        let birthdayTimestamp = defaults.double(forKey: "userProfile_birthday")
        if birthdayTimestamp > 0 { birthday = Date(timeIntervalSince1970: birthdayTimestamp) }
        if let imageData = defaults.data(forKey: "userProfile_imageData"),
           let image = UIImage(data: imageData) { profileImage = image }

        // 서버(DB)에서 최신 프로필 동기화
        do {
            let me = try await userService.fetchMe()
            userId = me.userId
            name = me.nickname
            email = me.email
            gender = me.gender.map { $0 == "M" ? .male : .female }
            birthday = me.birthday
            // 캐시 갱신 (다음 로드 시 깜빡임 방지)
            defaults.set(me.userId, forKey: "userProfile_userId")
            defaults.set(me.nickname, forKey: "userProfile_nickname")
            defaults.set(me.email, forKey: "userProfile_email")
            defaults.set(me.gender, forKey: "userProfile_gender")
            if let b = me.birthday { defaults.set(b.timeIntervalSince1970, forKey: "userProfile_birthday") }
            else { defaults.removeObject(forKey: "userProfile_birthday") }
            NotificationCenter.default.post(name: .userProfileUpdated, object: nil, userInfo: ["nickname": name])
        } catch {
            print("⚠️ 프로필 로드 실패 (DB 연동): \(error)")
            // 서버 실패 시 캐시 값 유지, mock 기본값은 사용하지 않음
            NotificationCenter.default.post(name: .userProfileUpdated, object: nil, userInfo: ["nickname": name])
        }
    }

    /// 프로필 저장 (PUT /api/users/me → DB 반영)
    func saveProfile() async {
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
        errorMessage = nil
        do {
            let updated = try await userService.updateMe(
                nickname: name,
                gender: gender,
                birthday: birthday
            )
            userId = updated.userId
            name = updated.nickname
            email = updated.email
            gender = updated.gender.map { $0 == "M" ? MyPageViewModel.Gender.male : MyPageViewModel.Gender.female }
            birthday = updated.birthday
            await MainActor.run { self.successMessage = "프로필이 저장되었습니다." }
            NotificationCenter.default.post(
                name: .userProfileUpdated,
                object: nil,
                userInfo: ["nickname": name]
            )
            
        } catch {
            print("❌ 프로필 저장 실패 (DB): \(error)")
            await MainActor.run { self.errorMessage = "저장에 실패했습니다. \(error.localizedDescription)" }
        }
        
        isLoading = false
        print("✅ saveProfile() 완료")
    }

    /// 로그아웃: 서버 호출 후 로컬 정리, NotificationCenter로 앱 로그인 상태 갱신
    func logout() async {
        do {
            try await userService.logout()
        } catch {
            print("⚠️ 로그아웃 실패: \(error)")
        }
        // 로그인 계정 프로필 캐시 삭제 (다음 로그인 시 이전 계정 정보 안 보이게)
        Self.clearProfileCache()
        // 로컬 토큰 정리
        AuthStorage.shared.clear()
        SessionStore.clear()
        // StartView가 AppState.logout() 호출해 Register 화면으로 전환
        NotificationCenter.default.post(name: .logoutCompleted, object: nil)
    }

    /// UserDefaults에 저장된 프로필 캐시 삭제 (로그아웃 시 호출)
    static func clearProfileCache() {
        let keys = [
            "userProfile_userId", "userProfile_nickname", "userProfile_email",
            "userProfile_gender", "userProfile_birthday", "userProfile_imageData"
        ]
        let defaults = UserDefaults.standard
        keys.forEach { defaults.removeObject(forKey: $0) }
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

    /// 스크린샷 목록 로드 (GET /api/screenshots → DB screenshot_file 기준)
    func refreshScreenshots() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await screenshotService.fetchMyScreenshots(cursor: nil)
            screenshots = page.items
            nextCursor = page.nextCursor
            savedCount = page.items.count
        } catch {
            print("⚠️ 스크린샷 로드 실패 (DB): \(error)")
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
            print("⚠️ 추가 스크린샷 로드 실패: \(error)")
            // ✅ 서버 연결 실패를 사용자에게 알리지 않음
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
