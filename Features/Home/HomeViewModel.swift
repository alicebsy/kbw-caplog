import SwiftUI
import Combine

// MARK: - ViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - UI State
    @Published var showNotificationView: Bool = false
    @Published var showMyPageView: Bool = false
    @Published var isImportingScreenshots: Bool = false
    
    // MARK: - Data (서버/캐시 기반, mock 기본값 없음)
    @Published var userName: String = {
        return UserDefaults.standard.string(forKey: "userProfile_nickname") ?? ""
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
        // ② 카드가 수정/삭제/최근본 변경될 때마다 HomeView 전체 자동 리로드
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
            // 서버 실패 시 캐시만 유지 (mock 기본값 사용 안 함)
            if userName.isEmpty, let cached = UserDefaults.standard.string(forKey: "userProfile_nickname") {
                userName = cached
            }
            print("⚠️ HomeViewModel: 사용자 정보 로드 실패 (DB)")
        }
        
        // 2) 카드 전체 로드
        await cardManager.loadAllCards()
        
        // 3) 홈 화면 내용 채우기 (최근 본 카드까지 포함)
        await reloadHomeContent()
        
        // 4) 기존 스크린샷 최근 5장 한 번만 AI 분류 (폰 갤러리 연동)
        Task {
            await ScreenshotIndexer.shared.importRecentScreenshotsIfNeeded(limit: 5)
        }
        
        print("🏠 HomeViewModel: 홈 초기 로드 완료")
    }

    /// 갤러리 스크린샷 앨범에서 최근 5장을 다시 가져와서 카드로 만듦 (홈에서 수동 트리거)
    func importScreenshotsFromGallery() async {
        guard !isImportingScreenshots else { return }
        isImportingScreenshots = true
        await ScreenshotIndexer.shared.forceImportRecentScreenshots(limit: 5)
        await reloadHomeContent()
        isImportingScreenshots = false
    }
    
    
    // ===================================================================
    // MARK: - 갱신 로직 (카드 수정/삭제/태그/최근본 변경 시 자동 호출)
    // ===================================================================
    func reloadHomeContent() async {
        // Recommended
        recommended = cardManager.recommendedCards(limit: 5)
        
        // Coupons (만료일이 지나지 않은 것만 표시)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy. MM. dd."
        let now = Date()
        
        coupons = cardManager.cards(for: .info, subcategory: "쿠폰")
            .filter { card in
                // 만료일 필드가 있는 경우에만 필터링
                guard let expiryString = card.fields["만료일"],
                      let expiryDate = dateFormatter.date(from: expiryString) else {
                    return false // 만료일이 없으면 표시하지 않음
                }
                // 만료일이 현재 날짜보다 이후인 것만 표시
                return expiryDate >= now
            }
            .sorted(by: { $0.fields["만료일", default: "" ] < $1.fields["만료일", default: "" ] })
            .prefix(3) // 가장 가까운 3개만
            .map { $0 }
        
        // Recently viewed  → 항상 CardManager 상태 기반으로 직접 계산
        recent = cardManager.recentlyViewedCards(limit: 3)
        
        print("""
        🔄 HomeViewModel: 홈 데이터 갱신됨
        - 쿠폰: \(coupons.count)
        - 추천: \(recommended.count)
        - 최근:  \(recent.count)
        """)
    }
}
