import Foundation

struct SearchQueryDTO: Encodable {
    let query: String
    let tags: [String]        // 카테고리에서 온 토큰들
    let page: Int
    let size: Int
}

struct SearchItem: Identifiable, Decodable, Hashable {
    let id: String
    let title: String
    let snippet: String
    let description: String?
    let thumbnailURL: URL?
    let createdAt: Date
    let category: MajorCategory?
    let subCategory: SubCategory?
}

struct SearchResponse: Decodable {
    let items: [SearchItem]
    let nextPage: Int?
}
