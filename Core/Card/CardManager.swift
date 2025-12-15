import Foundation
import Combine

/// 전역 카드 상태 관리
/// Home, Folder, Search, Share 모든 탭에서 공유
@MainActor
final class CardManager: ObservableObject {
    
    // ✅ 1. 싱글톤 인스턴스 생성
    static let shared = CardManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var allCards: [Card] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // ✅ 2. "최근 본" 카드 ID 목록 (Published로 선언)
    @Published private(set) var viewedCardIDs: [UUID] = []
    private let viewedCardsKey = "recentlyViewedCardIDs" // UserDefaults 키

    // MARK: - Dependencies
    
    private lazy var service: CardService = CardService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    // ✅ 3. init을 private으로 변경 (외부 생성 방지)
    private nonisolated init() {
        // ✅ 4. 앱 실행 시 UserDefaults에서 "최근 본" 목록 로드
        let savedIDs = UserDefaults.standard.array(forKey: viewedCardsKey) as? [String] ?? []
        let uuids = savedIDs.compactMap { UUID(uuidString: $0) }
        
        // MainActor에서 published 프로퍼티 업데이트
        DispatchQueue.main.async {
            self.viewedCardIDs = uuids
        }
    }
    
    // MARK: - Load Methods
    
    /// 모든 카드 로드
    func loadAllCards() async {
        guard allCards.isEmpty || isLoading == false else {
            print("ℹ️ CardManager: 이미 카드를 로드 중이거나 로드했습니다.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            allCards = try await service.fetchAllCards()
            print("✅ CardManager: \(allCards.count)개 카드 로드 완료")
        } catch {
            errorMessage = "카드를 불러오는데 실패했습니다: \(error.localizedDescription)"
            print("❌ CardManager 에러: \(error)")
        }
        
        isLoading = false
    }
    
    /// 카테고리별 카드 필터링 (로컬)
    func cards(for category: FolderCategory, subcategory: String? = nil) -> [Card] {
        var filtered = allCards.filter { $0.category == category }
        
        if let sub = subcategory {
            filtered = filtered.filter { $0.subcategory == sub }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// 검색 (로컬)
    func searchCards(query: String) -> [Card] {
        guard !query.isEmpty else { return allCards }
        
        let lowercased = query.lowercased()
        return allCards.filter { card in
            card.title.lowercased().contains(lowercased) ||
            card.summary.lowercased().contains(lowercased) ||
            card.subcategory.lowercased().contains(lowercased) ||
            card.tags.contains { $0.lowercased().contains(lowercased) } ||
            card.location.lowercased().contains(lowercased)
        }
    }
    
    /// 추천 카드 (최근 생성 순)
    func recommendedCards(limit: Int = 10) -> [Card] {
        Array(allCards.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    
    /// "최근 본 카드" 객체를 반환하는 새 함수
    func recentlyViewedCards(limit: Int = 3) -> [Card] {
        return viewedCardIDs.prefix(limit).compactMap { id in
            allCards.first { $0.id == id }
        }
    }
    
    // ✅ "카드를 봤음"이라고 등록하는 함수 (수정됨)
    func markCardAsViewed(_ card: Card) {
        let id = card.id
        
        // ✅ 수정: HomeViewModel이 갱신을 감지하도록 수동으로 '변경 알림'을 보냅니다.
        // 이것이 1위 항목을 다시 눌러도 갱신되게 하는 핵심입니다.
        objectWillChange.send()

        var currentIDs = self.viewedCardIDs
        currentIDs.removeAll { $0 == id }
        currentIDs.insert(id, at: 0)
        
        if currentIDs.count > 10 {
            currentIDs = Array(currentIDs.prefix(10))
        }
        
        self.viewedCardIDs = currentIDs
        
        let stringIDs = currentIDs.map { $0.uuidString }
        UserDefaults.standard.set(stringIDs, forKey: viewedCardsKey)
        print("✅ CardManager: \(card.title)을(를) 최근 본 카드로 등록. 총 \(currentIDs.count)개")
    }

    // MARK: - CRUD Methods
    
    /// 카드 생성
    func createCard(_ card: Card) async {
        do {
            let newCard = try await service.createCard(card)
            allCards.append(newCard)
            print("✅ CardManager: 카드 생성 완료 - \(newCard.title)")
        } catch {
            errorMessage = "카드 생성 실패: \(error.localizedDescription)"
            print("❌ CardManager 생성 에러: \(error)")
        }
    }
    
    /// 카드 수정
    func updateCard(_ card: Card) async {
        do {
            let updated = try await service.updateCard(card)
            if let index = allCards.firstIndex(where: { $0.id == card.id }) {
                allCards[index] = updated
                print("✅ CardManager: 카드 수정 완료 - \(updated.title)")
            }
        } catch {
            errorMessage = "카드 수정 실패: \(error.localizedDescription)"
            print("❌ CardManager 수정 에러: \(error)")
        }
    }
    
    /// 카드 삭제
    func deleteCard(id: UUID) async {
        do {
            try await service.deleteCard(id: id)
            allCards.removeAll { $0.id == id }
            viewedCardIDs.removeAll { $0 == id }
            print("✅ CardManager: 카드 삭제 완료")
        } catch {
            errorMessage = "카드 삭제 실패: \(error.localizedDescription)"
            print("❌ CardManager 삭제 에러: \(error)")
        }
    }
    
    /// 특정 카드 찾기
    func card(withId id: UUID) -> Card? {
        allCards.first { $0.id == id }
    }
    
    // MARK: - Utility
    
    /// 에러 메시지 초기화
    func clearError() {
        errorMessage = nil
    }
}
