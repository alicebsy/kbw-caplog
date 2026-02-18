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
        
        // 4) 기존 스크린샷 최근 20장 한 번만 AI 분류 (폰 갤러리 연동)
        Task {
            await ScreenshotIndexer.shared.importRecentScreenshotsIfNeeded(limit: 20)
        }
        
        print("🏠 HomeViewModel: 홈 초기 로드 완료")
    }

    /// 갤러리 스크린샷 앨범에서 최근 20장을 가져와서 카드로 만듦 (이미 처리된 건 스킵)
    func importScreenshotsFromGallery() async {
        guard !isImportingScreenshots else { return }
        isImportingScreenshots = true
        await ScreenshotIndexer.shared.forceImportRecentScreenshots(limit: 20)
        await reloadHomeContent()
        isImportingScreenshots = false
    }

    /// 기존 처리 목록 초기화 후, 최근 스크린샷 전부 다시 인식·OCR·카드 생성 (한번 더 돌리기)
    func reimportAllScreenshotsFromGallery() async {
        guard !isImportingScreenshots else { return }
        isImportingScreenshots = true
        await ScreenshotIndexer.shared.resetAndReimportScreenshots(limit: 50)
        await reloadHomeContent()
        isImportingScreenshots = false
    }
    
    
    // ===================================================================
    // MARK: - 갱신 로직 (카드 수정/삭제/태그/최근본 변경 시 자동 호출)
    // ===================================================================
    /// 여러 날짜 형식 파싱 (yyyy.MM.dd., yyyy-MM-dd, yy.MM.dd 등)
    private static func parseDate(_ s: String) -> Date? {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        let formatters: [DateFormatter] = {
            let formats = ["yyyy. MM. dd.", "yyyy.MM.dd", "yyyy-MM-dd", "yy. MM. dd.", "yy.MM.dd", "MM/dd/yyyy", "yyyy/MM/dd"]
            return formats.map { f in
                let df = DateFormatter()
                df.dateFormat = f
                df.locale = Locale(identifier: "en_US_POSIX")
                return df
            }
        }()
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }

    /// 같은 카드가 여러 번 나오지 않도록 ID 기준 중복 제거 (순서 유지)
    private static func deduplicateByID(_ cards: [Card]) -> [Card] {
        var seen = Set<UUID>()
        return cards.filter { seen.insert($0.id).inserted }
    }

    func reloadHomeContent() async {
        // 마감 임박: 쿠폰·공고·취업 등 만료일 있는 카드(미래 기준) + 만료일 없는 쿠폰도 포함, 날짜 순 후 만료일 없는 건 맨 뒤
        let now = Date()
        let expiringCandidate: [Card] = cardManager.allCards.filter { card in
            let isCouponOrDeadlineType = card.subcategory == "쿠폰" || card.subcategory == "공고" || card.subcategory == "취업"
            guard isCouponOrDeadlineType else { return false }
            let dateString = card.fields["만료일"] ?? card.fields["valid_until"] ?? card.fields["deadline"] ?? ""
            if dateString.isEmpty { return card.subcategory == "쿠폰" } // 쿠폰은 만료일 없어도 표시
            guard let date = Self.parseDate(dateString) else { return card.subcategory == "쿠폰" }
            return date >= now
        }
        var expiringSorted = expiringCandidate.sorted { c1, c2 in
            let s1 = c1.fields["만료일"] ?? c1.fields["valid_until"] ?? c1.fields["deadline"] ?? ""
            let s2 = c2.fields["만료일"] ?? c2.fields["valid_until"] ?? c2.fields["deadline"] ?? ""
            let hasDate1 = !s1.isEmpty && Self.parseDate(s1) != nil
            let hasDate2 = !s2.isEmpty && Self.parseDate(s2) != nil
            if hasDate1, hasDate2, let d1 = Self.parseDate(s1), let d2 = Self.parseDate(s2) { return d1 < d2 }
            if hasDate1 { return true }
            if hasDate2 { return false }
            return s1 < s2
        }
        coupons = Self.deduplicateByID(expiringSorted).prefix(5).map { $0 }

        // Recommended: 최근 생성 순, 마감 임박에 이미 나온 카드는 제외 (같은 것 여러 번 안 나오게)
        let expiringIds = Set(coupons.map(\.id))
        recommended = Self.deduplicateByID(cardManager.recommendedCards(limit: 10).filter { !expiringIds.contains($0.id) })
            .prefix(5).map { $0 }

        // Recently viewed: 마감 임박·추천에 이미 나온 카드 제외
        let recommendedIds = Set(recommended.map(\.id))
        let excludeIds = expiringIds.union(recommendedIds)
        recent = Self.deduplicateByID(cardManager.recentlyViewedCards(limit: 5).filter { !excludeIds.contains($0.id) })
            .prefix(3).map { $0 }
        
        print("""
        🔄 HomeViewModel: 홈 데이터 갱신됨
        - 쿠폰: \(coupons.count)
        - 추천: \(recommended.count)
        - 최근:  \(recent.count)
        """)
    }
}
