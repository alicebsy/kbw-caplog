import Foundation

/// 카드 CRUD API 서비스 (백엔드 GET /api/cards 연동)
struct CardService {
    private let client = APIClient()
    /// Mock 사용 여부 (false: 실제 백엔드 연동)
    private let useMockData = false

    // MARK: - Card CRUD

    /// 모든 카드 조회 (GET /api/cards, JWT Bearer 필요)
    func fetchAllCards() async throws -> [Card] {
        if useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000)
            return Card.sampleCards
        }
        let dtos: [CardResponseDto] = try await client.request("GET", path: Endpoints.cards)
        return dtos.map { $0.toCard() }
    }
    
    /// 카테고리별 카드 조회 (서버에서 전체 조회 후 로컬 필터)
    func fetchCards(category: FolderCategory, subcategory: String? = nil) async throws -> [Card] {
        let all = try await fetchAllCards()
        var filtered = all.filter { $0.category == category }
        if let sub = subcategory {
            filtered = filtered.filter { $0.subcategory == sub }
        }
        return filtered
    }
    
    /// 카드 검색 (서버에서 전체 조회 후 로컬 검색)
    func searchCards(query: String) async throws -> [Card] {
        let all = try await fetchAllCards()
        return all.filter { card in
            card.title.localizedCaseInsensitiveContains(query) ||
            card.summary.localizedCaseInsensitiveContains(query) ||
            card.subcategory.localizedCaseInsensitiveContains(query) ||
            card.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    /// 추천 카드 조회 (최신순 limit개)
    func fetchRecommendedCards(limit: Int = 10) async throws -> [Card] {
        let all = try await fetchAllCards()
        return Array(all.prefix(limit))
    }

    /// 현재 위치 주변의 내 장소 카드를 거리순으로 조회합니다.
    func fetchNearbyCards(
        latitude: Double,
        longitude: Double,
        radiusMeters: Int = 1_000,
        limit: Int = 3
    ) async throws -> [Card] {
        let query = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "radiusMeters", value: String(radiusMeters)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        let dtos: [NearbyCardResponseDto] = try await client.request(
            "GET",
            path: Endpoints.nearbyRecommendations,
            query: query
        )
        return dtos.map { $0.toCard() }
    }

    /// 최근 카드 조회 (최신순 limit개)
    func fetchRecentCards(limit: Int = 10) async throws -> [Card] {
        let all = try await fetchAllCards()
        return Array(all.prefix(limit))
    }
    
    /// 카드 생성 (POST /api/cards → DB 저장 후 응답 카드 반환)
    func createCard(_ card: Card) async throws -> Card {
        let body = CreateCardRequestBody(card: card)
        let dto: CardResponseDto = try await client.request("POST", path: Endpoints.cards, body: body)
        return dto.toCard()
    }

    /// 카드 수정 (PUT /api/cards/{id})
    func updateCard(_ card: Card) async throws -> Card {
        let body = CreateCardRequestBody(card: card)
        let dto: CardResponseDto = try await client.request(
            "PUT",
            path: Endpoints.card(card.id),
            body: body
        )
        return dto.toCard()
    }

    /// 카드 삭제 (DELETE /api/cards/{id})
    func deleteCard(id: UUID) async throws {
        try await client.requestVoid("DELETE", path: Endpoints.card(id))
    }
}

// MARK: - 카드 생성 요청 body (백엔드 CreateCardRequest와 매핑)
private struct CreateCardRequestBody: Encodable {
    let title: String
    let summary: String
    let category: String
    let subcategory: String
    let tags: [String]
    let fields: [String: String]
    let thumbnailURL: String?
    let screenshotURLs: [String]?

    init(card: Card) {
        title = card.title
        summary = card.summary
        category = card.category.rawValue
        subcategory = card.subcategory
        tags = card.tags
        fields = card.fields
        thumbnailURL = card.thumbnailURL
        screenshotURLs = card.screenshotURLs.isEmpty ? nil : card.screenshotURLs
    }
}

// MARK: - API 응답 DTO (백엔드 CardDto와 매핑)
private struct CardResponseDto: Decodable {
    let id: String
    let title: String
    let summary: String?
    let category: String?
    let subcategory: String?
    let tags: [String]?
    let fields: [String: String]?
    let createdAt: Date?
    let updatedAt: Date?
    let thumbnailURL: String?
    let screenshotURLs: [String]?

    func toCard() -> Card {
        let cat = FolderCategory(rawValue: category ?? "Etc.") ?? .etc
        return Card(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            summary: summary ?? "",
            category: cat,
            subcategory: subcategory ?? "기타",
            tags: tags ?? [],
            fields: fields ?? [:],
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            thumbnailURL: thumbnailURL,
            screenshotURLs: screenshotURLs ?? []
        )
    }
}

private struct NearbyCardResponseDto: Decodable {
    let id: Int64
    let title: String?
    let summary: String?
    let placeName: String?
    let address: String?
    let imageUrl: String?
    let distanceMeters: Double?

    func toCard() -> Card {
        let uuidString = String(format: "00000000-0000-0000-0000-%012llx", id)
        var fields: [String: String] = [:]
        if let placeName, !placeName.isEmpty { fields["장소명"] = placeName }
        if let address, !address.isEmpty { fields["주소"] = address }
        if let distanceMeters {
            fields["거리"] = distanceMeters < 1_000
                ? "\(Int(distanceMeters.rounded()))m"
                : String(format: "%.1fkm", distanceMeters / 1_000)
        }
        return Card(
            id: UUID(uuidString: uuidString) ?? UUID(),
            title: title ?? placeName ?? "주변 장소",
            summary: summary ?? "",
            category: .info,
            subcategory: "맛집",
            fields: fields,
            thumbnailURL: imageUrl,
            screenshotURLs: imageUrl.map { [$0] } ?? []
        )
    }
}
