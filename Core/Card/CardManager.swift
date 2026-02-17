import Foundation
import Combine

/// 전역 카드 상태 관리 (DB 연동)
/// - 카드 목록: GET /api/cards (서버 Screenshot 기반)
/// - Home, Folder, Search, Share 탭에서 공유
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

    /// 스크린샷으로 생성된 카드 ID (서버에 없을 수 있음 → load 시 유지)
    private var localOnlyCardIds: Set<UUID> = []

    // MARK: - Dependencies
    
    private lazy var service: CardService = CardService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    // ✅ 3. init을 private으로 변경 (외부 생성 방지)
    @MainActor
    private init() {
        // ✅ 4. 앱 실행 시 UserDefaults에서 "최근 본" 목록 로드
        let savedIDs = UserDefaults.standard.array(forKey: viewedCardsKey) as? [String] ?? []
        let uuids = savedIDs.compactMap { UUID(uuidString: $0) }
        self.viewedCardIDs = uuids
        print("🔧 CardManager init: 최근 본 카드 \(uuids.count)개 로드됨")
    }
    
    // MARK: - Load Methods
    
    /// 카드 전체 로드 (GET /api/cards → DB). 스크린샷으로 만든 로컬 카드는 유지.
    func loadAllCards() async {
        guard !isLoading else {
            print("ℹ️ CardManager: 이미 카드를 로드 중입니다.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        let localCardsToKeep = allCards.filter { localOnlyCardIds.contains($0.id) }
        do {
            let serverCards = try await service.fetchAllCards()
            allCards = serverCards + localCardsToKeep
            print("✅ CardManager: 서버 \(serverCards.count)개 + 로컬(스크린샷) \(localCardsToKeep.count)개")
        } catch {
            errorMessage = "카드를 불러오는데 실패했습니다: \(error.localizedDescription)"
            // 실패 시에도 로컬 카드는 유지
            if !localCardsToKeep.isEmpty {
                allCards = localCardsToKeep
            }
        }
        isLoading = false
    }

    /// DB에서 카드 목록 강제 새로고침 (로컬 스크린샷 카드는 유지)
    func reloadAllCards() async {
        await loadAllCards()
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
    
    // ✅ "카드를 봤음"이라고 등록하는 함수
    func markCardAsViewed(_ card: Card) {
        let id = card.id
        
        // HomeViewModel 등에서 변경을 감지할 수 있도록
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
        
        // ✅ 홈(및 다른 탭)에서 reloadHomeContent()를 트리거
        NotificationCenter.default.post(name: .cardUpdated, object: nil)
    }

    // MARK: - CRUD Methods
    
    /// 카드 생성 (스크린샷 AI 분류 결과 등). 서버 저장 성공 시 DB 반영, 실패 시 로컬만 유지.
    func createCard(_ card: Card) async {
        ScreenshotPipelineStatus.shared.setPostSending()
        do {
            let newCard = try await service.createCard(card)
            allCards.append(newCard)
            ScreenshotPipelineStatus.shared.setPostSuccess(cardTitle: newCard.title)
            NotificationCenter.default.post(name: .cardUpdated, object: nil)
        } catch {
            allCards.append(card)
            localOnlyCardIds.insert(card.id)
            ScreenshotPipelineStatus.shared.setPostFailed(errorDescription: error.localizedDescription)
            print("❌ CardManager: 서버 저장 실패 → 로컬만 유지 - \(card.title) | \(error.localizedDescription)")
            NotificationCenter.default.post(name: .cardUpdated, object: nil)
        }
    }
    
    /// 카드 수정
    func updateCard(_ card: Card) async {
        print("================================================================================")
        print("🔧 CardManager.updateCard 호출됨")
        print("🔧 수정하려는 카드:")
        print("   - ID: \(card.id)")
        print("   - Title: \(card.title)")
        print("   - Category: \(card.category.rawValue)")
        print("   - Subcategory: \(card.subcategory)")
        print("================================================================================")
        
        print("🔧 현재 allCards 배열 상태:")
        for (idx, c) in allCards.enumerated() {
            print("   [\(idx)] id=\(c.id), title=\(c.title)")
        }
        
        do {
            let updated = try await service.updateCard(card)
            print("✅ service.updateCard() 완료")
            
            if let index = allCards.firstIndex(where: { $0.id == card.id }) {
                print("✅ allCards에서 인덱스 발견: \(index)")
                print("🔧 업데이트 전:")
                print("   allCards[\(index)].title = '\(allCards[index].title)'")
                print("   allCards[\(index)].category = '\(allCards[index].category.rawValue)'")
                print("   allCards[\(index)].subcategory = '\(allCards[index].subcategory)'")
                
                // 배열 전체를 새로 생성하여 재할당
                var updatedCards = allCards
                updatedCards[index] = updated
                allCards = updatedCards
                
                print("✅ allCards 배열 업데이트 완료!")
                print("🔧 업데이트 후:")
                print("   allCards[\(index)].title = '\(allCards[index].title)'")
                print("   allCards[\(index)].category = '\(allCards[index].category.rawValue)'")
                print("   allCards[\(index)].subcategory = '\(allCards[index].subcategory)'")
                
                print("================================================================================")
                print("🔧 최종 allCards 배열 상태:")
                for (idx, c) in allCards.enumerated() {
                    print("   [\(idx)] id=\(c.id), title=\(c.title)")
                }
                print("================================================================================")
                
                // 홈 화면 갱신을 위한 알림
                NotificationCenter.default.post(name: .cardUpdated, object: nil)
            } else {
                print("❌ 오류: allCards에서 카드를 찾을 수 없음!")
                print("   찾으려던 ID: \(card.id)")
                print("   현재 allCards의 모든 ID들:")
                for (idx, c) in allCards.enumerated() {
                    print("   [\(idx)]: \(c.id)")
                }
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
            localOnlyCardIds.remove(id)
            print("✅ CardManager: 카드 삭제 완료")
            NotificationCenter.default.post(name: .cardUpdated, object: nil)
        } catch {
            allCards.removeAll { $0.id == id }
            viewedCardIDs.removeAll { $0 == id }
            localOnlyCardIds.remove(id)
            print("✅ CardManager: 카드 로컬에서 삭제")
            NotificationCenter.default.post(name: .cardUpdated, object: nil)
        }
    }
    
    /// 특정 카드 찾기
    func card(withId id: UUID) -> Card? {
        let found = allCards.first { $0.id == id }
        if let card = found {
            print("🔍 card(withId:) 호출 - ID: \(id)")
            print("   ✅ 찾음: '\(card.title)' (category: \(card.category.rawValue), subcategory: \(card.subcategory))")
        } else {
            print("🔍 card(withId:) 호출 - ID: \(id)")
            print("   ❌ 찾지 못함!")
        }
        return found
    }
    
    // MARK: - Utility
    
    /// 에러 메시지 초기화
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let cardUpdated = Notification.Name("cardUpdated")
}
