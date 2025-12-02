// HomeViewModel.swift

import SwiftUI
import Combine

// MARK: - ViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - UI State
    @Published var showNotificationView: Bool = false
    @Published var showMyPageView: Bool = false
    
    // MARK: - Data
    @Published var userName: String = {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "userProfile_nickname") ?? "강배우"
    }()
    @Published var coupons: [Card] = []
    @Published var recommended: [Card] = []
    @Published var recent: [Card] = []
    
    private let friendManager = FriendManager.shared
    var friends: [Friend] { friendManager.friends }
    
    private let cardManager: CardManager
    private let userService = UserService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        self.cardManager = CardManager.shared
        
        // ---------------------------------------------------
        // ① MyPage → 이름 변경 반영
        // ---------------------------------------------------
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let nickname = notification.userInfo?["nickname"] as? String {
                    self?.userName = nickname
                    print("🔄 HomeViewModel: 이름 업데이트 → \(nickname)")
                }
            }
            .store(in: &cancellables)
        
        
        // ---------------------------------------------------
        // ② CardManager에서 최근 본 카드 리로드
        // ---------------------------------------------------
        Publishers.CombineLatest(
            cardManager.$viewedCardIDs,
            cardManager.$allCards
        )
        .map { [weak self] (_, _) -> [Card] in
            guard let self else { return [] }
            return self.cardManager.recentlyViewedCards(limit: 3)
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$recent)
        
        
        // ---------------------------------------------------
        // ③ 카드가 수정/삭제될 때마다 HomeView 전체 자동 리로드
        // ---------------------------------------------------
        NotificationCenter.default.publisher(for: .cardUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.reloadHomeContent() }
            }
            .store(in: &cancellables)
    }
    
    
    // ===================================================================
    // MARK: - 초기 로드
    // ===================================================================
    func load() async {
        // 0) UserDefaults 기반 즉시 로드 (깜빡임 방지)
        let defaults = UserDefaults.standard
        if let savedNickname = defaults.string(forKey: "userProfile_nickname") {
            userName = savedNickname
        }
        
        // 1) 사용자 정보 (서버 동기화)
        do {
            let userProfile = try await userService.fetchMe()
            userName = userProfile.nickname
            // 서버에서 최신 값 받아오면 UserDefaults도 업데이트
            defaults.set(userProfile.nickname, forKey: "userProfile_nickname")
        } catch {
            // 이미 UserDefaults에서 로드했으므로, 값이 비어 있을 때만 기본값 사용
            if userName.isEmpty {
                userName = "강배우"
            }
            print("⚠️ HomeViewModel: 사용자 정보 로드 실패 → UserDefaults/기본값 사용")
        }
        
        // 2) 카드 전체 로드
        await cardManager.loadAllCards()
        
        // 3) 홈 화면 내용 채우기
        await reloadHomeContent()
        
        print("🏠 HomeViewModel: 홈 초기 로드 완료")
    }
    
    
    // ===================================================================
    // MARK: - 갱신 로직 (카드 수정/삭제/태그 변경 시 자동 호출)
    // ===================================================================
    func reloadHomeContent() async {
        // Recommended
        recommended = cardManager.recommendedCards(limit: 5)
        
        // Coupons
        coupons = cardManager.cards(for: .info, subcategory: "쿠폰")
            .sorted(by: { $0.fields["만료일", default: ""] < $1.fields["만료일", default: ""] })
        
        // Recently viewed  → CombineLatest로 자동 반영됨 (recent는 자동 관리)
        
        print("""
        🔄 HomeViewModel: 홈 데이터 갱신됨
        - 쿠폰: \(coupons.count)
        - 추천: \(recommended.count)
        - 최근:  \(recent.count)
        """)
    }
}
