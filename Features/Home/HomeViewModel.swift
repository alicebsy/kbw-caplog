import SwiftUI
import Combine

// MARK: - ViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    struct CouponInfo {
        var title: String
        var expireDate: String
        var brand: String
        var screenshotName: String?
    }

    // 화면 상태
    @Published var showNotificationView: Bool = false
    @Published var showMyPageView: Bool = false

    // 데이터
    @Published var userName: String = "강배우"
    @Published var coupon: CouponInfo = .init(title: "", expireDate: "", brand: "", screenshotName: nil)
    @Published var recommended: [Content] = []

    // 공유용 친구 목록(임시)
    @Published var friends: [ShareFriend] = [
        .init(id: UUID(), name: "다혜", avatar: "avatar1"),
        .init(id: UUID(), name: "서연", avatar: "avatar2"),
        .init(id: UUID(), name: "민하", avatar: "avatar3"),
        .init(id: UUID(), name: "바리", avatar: "avatar4")
    ]
    
    // ✅ 🔥 추가: UserService 인스턴스
    private let userService = UserService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // ✅ 🔥 추가: MyPage에서 프로필 업데이트 알림 수신
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .sink { [weak self] notification in
                if let nickname = notification.userInfo?["nickname"] as? String {
                    print("✅ HomeViewModel: 사용자 이름 업데이트됨 - \(nickname)")
                    self?.userName = nickname
                }
            }
            .store(in: &cancellables)
    }

    func load() async {
        // ✅ 🔥 수정: UserService에서 실제 사용자 정보 로드
        do {
            let userProfile = try await userService.fetchMe()
            userName = userProfile.nickname
            print("✅ HomeViewModel: 사용자 이름 로드됨 - \(userName)")
        } catch {
            print("⚠️ HomeViewModel: 사용자 정보 로드 실패 (Mock 사용): \(error)")
            // Mock 데이터
            userName = "강배우"
        }
        
        // TODO: Spring Boot API 연동 (쿠폰, 추천 콘텐츠)
        // let url = URL(string: "https://api.caplog.com/home")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // let decoded = try JSONDecoder().decode(HomeResponse.self, from: data)
        // self.coupon   = .init(title: decoded.coupon.title, expireDate: decoded.coupon.expire, brand: decoded.coupon.brand, screenshotName: decoded.coupon.image)
        // self.recommended = decoded.recommended

        // 데모 데이터
        self.coupon = .init(
            title: "무료 음료 쿠폰",
            expireDate: "2025-10-20",
            brand: "Starbucks",
            screenshotName: "shot_coupon"
        )
        self.recommended = sampleContents
    }
}
