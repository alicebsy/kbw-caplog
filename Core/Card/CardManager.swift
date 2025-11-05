import Foundation
import Combine

/// 전역 카드 상태 관리
/// Home, Folder, Search, Share 모든 탭에서 공유
@MainActor
final class CardManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var allCards: [Card] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // MARK: - Dependencies
    
    private lazy var service: CardService = CardService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    nonisolated init() {
    }
    
    // MARK: - Load Methods
    
    /// 모든 카드 로드
    func loadAllCards() async {
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
    
    /// 최근 카드
    func recentCards(limit: Int = 10) -> [Card] {
        Array(allCards.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
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
