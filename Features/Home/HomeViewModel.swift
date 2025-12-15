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
    @Published var coupons: [Card] = []
    @Published var recommended: [Card] = []
    @Published var recent: [Card] = []

    // FriendManager 사용
    private let friendManager = FriendManager.shared
    var friends: [ShareFriend] { friendManager.friends }
    
    // CardManager 사용
    private let cardManager: CardManager
    private let userService = UserService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.cardManager = CardManager.shared
        
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
        
        // CardManager의 "최근 본" ID 목록을 구독
        cardManager.$viewedCardIDs
            .receive(on: DispatchQueue.main)
            .map { [weak self] (viewedIDs: [UUID]) in
                self?.cardManager.recentlyViewedCards(limit: 3) ?? []
            }
            .assign(to: &$recent)
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
        
        // 추천 카드 가져오기
        recommended = cardManager.recommendedCards(limit: 5)
        
        // ✅ 수정: 쿠폰 데이터를 직접 만들지 않고, CardManager에서 가져옴
        self.coupons = cardManager.cards(for: .info, subcategory: "쿠폰")
            .sorted(by: { $0.fields["만료일", default: ""] < $1.fields["만료일", default: ""] })
        
        print("✅ HomeViewModel: 쿠폰 \(coupons.count)개, 추천 \(recommended.count)개, 최근 \(recent.count)개 카드 로드 완료")
    }
}
