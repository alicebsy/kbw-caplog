import SwiftUI
import Combine

// MARK: - ViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    // 화면 상태
    @Published var showNotificationView: Bool = false
    @Published var showMyPageView: Bool = false

    // 데이터
    @Published var userName: String = "강배우"
    @Published var coupons: [Card] = []  // ✅ 수정: 단일 coupon -> coupons 배열
    @Published var recommended: [Card] = []
    @Published var recent: [Card] = []

    // ✅ FriendManager 사용
    private let friendManager = FriendManager.shared
    var friends: [ShareFriend] { friendManager.friends }
    
    // ✅ CardManager 사용
    private let cardManager: CardManager
    private let userService = UserService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.cardManager = CardManager()
        
        // MyPage에서 프로필 업데이트 알림 수신
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let nickname = notification.userInfo?["nickname"] as? String {
                    print("✅ HomeViewModel: 사용자 이름 업데이트됨 - \(nickname)")
                    self?.userName = nickname
                }
            }
            .store(in: &cancellables)
    }

    func load() async {
        // 사용자 정보 로드
        do {
            let userProfile = try await userService.fetchMe()
            userName = userProfile.nickname
            print("✅ HomeViewModel: 사용자 이름 로드됨 - \(userName)")
        } catch {
            print("⚠️ HomeViewModel: 사용자 정보 로드 실패 (Mock 사용): \(error)")
            userName = "강배우"
        }
        
        // 카드 데이터 로드
        await cardManager.loadAllCards()
        
        // 추천 카드 및 최근 카드 가져오기
        recommended = cardManager.recommendedCards(limit: 5)
        recent = cardManager.recentCards(limit: 10)
        
        // ✅ 수정: 쿠폰 데이터를 3개 생성 (날짜 임박 순)
        self.coupons = [
            Card(
                title: "무료 음료 쿠폰",
                summary: "스타벅스 무료 음료 1잔",
                category: .info, subcategory: "쿠폰", tags: ["스타벅스", "무료음료"],
                fields: ["브랜드": "Starbucks", "만료일": "2025. 10. 20."],
                thumbnailURL: "shot_coupon", screenshotURLs: ["shot_coupon"]
            ),
            Card(
                title: "10,000원 할인권",
                summary: "올리브영 1만원 할인",
                category: .info, subcategory: "쿠폰", tags: ["올리브영", "할인"],
                fields: ["브랜드": "Olive Young", "만료일": "2025. 10. 22."],
                thumbnailURL: "placeholder", screenshotURLs: ["placeholder"]
            ),
            Card(
                title: "치킨 5,000원 할인",
                summary: "배달의민족 치킨 할인 쿠폰",
                category: .info, subcategory: "쿠폰", tags: ["배달", "치킨"],
                fields: ["브랜드": "배달의민족", "만료일": "2025. 10. 25."],
                thumbnailURL: "placeholder", screenshotURLs: ["placeholder"]
            )
        ]
        
        print("✅ HomeViewModel: 쿠폰 \(coupons.count)개, 추천 \(recommended.count)개, 최근 \(recent.count)개 카드 로드 완료")
    }
}
