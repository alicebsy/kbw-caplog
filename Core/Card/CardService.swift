import Foundation

/// 카드 CRUD API 서비스
struct CardService {
    private let client = APIClient()
    
    // Mock 모드 스위치 (개발 중에는 true, 프로덕션에서는 false)
    private var useMockData: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Card CRUD
    
    /// 모든 카드 조회
    func fetchAllCards() async throws -> [Card] {
        if useMockData {
            print("🔧 Mock: fetchAllCards() - 더미 데이터 반환")
            try? await Task.sleep(nanoseconds: 500_000_000)
            return Card.sampleCards
        }
        
        // TODO: 실제 API 연동
        return try await client.request("GET", path: "/cards")
    }
    
    /// 카테고리별 카드 조회
    func fetchCards(category: FolderCategory, subcategory: String? = nil) async throws -> [Card] {
        if useMockData {
            print("🔧 Mock: fetchCards(category: \(category.rawValue), subcategory: \(subcategory ?? "nil"))")
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            var filtered = Card.sampleCards.filter { $0.category == category }
            if let sub = subcategory {
                filtered = filtered.filter { $0.subcategory == sub }
            }
            return filtered
        }
        
        // TODO: 실제 API 연동
        let query = [
            URLQueryItem(name: "category", value: category.rawValue),
            subcategory.map { URLQueryItem(name: "subcategory", value: $0) }
        ].compactMap { $0 }
        
        return try await client.request("GET", path: "/cards", query: query)
    }
    
    /// 카드 검색
    func searchCards(query: String) async throws -> [Card] {
        if useMockData {
            print("🔧 Mock: searchCards(query: \(query))")
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            return Card.sampleCards.filter { card in
                card.title.localizedCaseInsensitiveContains(query) ||
                card.summary.localizedCaseInsensitiveContains(query) ||
                card.subcategory.localizedCaseInsensitiveContains(query) ||
                card.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        // TODO: 실제 API 연동
        let queryItems = [URLQueryItem(name: "q", value: query)]
        return try await client.request("GET", path: "/cards/search", query: queryItems)
    }
    
    /// 추천 카드 조회 (Home용)
    func fetchRecommendedCards(limit: Int = 10) async throws -> [Card] {
        if useMockData {
            print("🔧 Mock: fetchRecommendedCards(limit: \(limit))")
            try? await Task.sleep(nanoseconds: 300_000_000)
            return Array(Card.sampleCards.prefix(limit))
        }
        
        // TODO: 실제 API 연동
        let query = [URLQueryItem(name: "limit", value: "\(limit)")]
        return try await client.request("GET", path: "/cards/recommended", query: query)
    }
    
    /// 최근 카드 조회 (Home용)
    func fetchRecentCards(limit: Int = 10) async throws -> [Card] {
        if useMockData {
            print("🔧 Mock: fetchRecentCards(limit: \(limit))")
            try? await Task.sleep(nanoseconds: 300_000_000)
            return Array(Card.sampleCards.prefix(limit))
        }
        
        // TODO: 실제 API 연동
        let query = [URLQueryItem(name: "limit", value: "\(limit)")]
        return try await client.request("GET", path: "/cards/recent", query: query)
    }
    
    /// 카드 생성
    func createCard(_ card: Card) async throws -> Card {
        if useMockData {
            print("🔧 Mock: createCard() - 카드 생성 성공")
            try? await Task.sleep(nanoseconds: 500_000_000)
            return card
        }
        
        // TODO: 실제 API 연동
        return try await client.request("POST", path: "/cards", body: card)
    }
    
    /// 카드 수정
    func updateCard(_ card: Card) async throws -> Card {
        if useMockData {
            print("🔧 Mock: updateCard() - 카드 수정 성공")
            try? await Task.sleep(nanoseconds: 500_000_000)
            return card
        }
        
        // TODO: 실제 API 연동
        return try await client.request("PUT", path: "/cards/\(card.id.uuidString)", body: card)
    }
    
    /// 카드 삭제
    func deleteCard(id: UUID) async throws {
        if useMockData {
            print("🔧 Mock: deleteCard() - 카드 삭제 성공")
            try? await Task.sleep(nanoseconds: 500_000_000)
            return
        }
        
        // TODO: 실제 API 연동
        try await client.requestVoid("DELETE", path: "/cards/\(id.uuidString)")
    }
}
