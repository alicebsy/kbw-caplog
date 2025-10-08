import SwiftUI
import Combine

// MARK: - ViewModel (Spring Boot 연동 자리)
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
    @Published var userName: String = "사용자"
    @Published var coupon: CouponInfo = .init(title: "", expireDate: "", brand: "", screenshotName: nil)
    @Published var recommended: [Content] = []

    // 공유용 친구 목록(임시). 실제론 백엔드에서 가져와서 ShareFriend로 변환해 전달.
    @Published var friends: [ShareFriend] = [
        .init(id: UUID(), name: "다혜", avatar: "avatar1"),
        .init(id: UUID(), name: "서연", avatar: "avatar2"),
        .init(id: UUID(), name: "민하", avatar: "avatar3"),
        .init(id: UUID(), name: "바리", avatar: "avatar4")
    ]

    @MainActor
    func load() async {
        // TODO: Spring Boot API 연동 (URLSession/JSONDecoder)
        // let url = URL(string: "https://api.caplog.com/home")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // let decoded = try JSONDecoder().decode(HomeResponse.self, from: data)
        // self.userName = decoded.user.name
        // self.coupon   = .init(title: decoded.coupon.title, expireDate: decoded.coupon.expire, brand: decoded.coupon.brand, screenshotName: decoded.coupon.image)
        // self.recommended = decoded.recommended

        // 데모 데이터
        self.userName = "민하"
        self.coupon = .init(title: "무료 음료 쿠폰",
                            expireDate: "2025-09-30",
                            brand: "Starbucks",
                            screenshotName: "shot_coupon")
        self.recommended = sampleContents
    }
}
