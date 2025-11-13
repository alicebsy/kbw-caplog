import Foundation
import SwiftUI

// MARK: - (추가) 목업 카드용 고정 UUID
struct MockCardIDs {
    static let starbucksCoupon = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    static let oliveYoungCoupon = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
    static let chickenCoupon = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
    static let makguksu = UUID(uuidString: "10000000-0000-0000-0000-000000000004")!
    static let nangman = UUID(uuidString: "10000000-0000-0000-0000-000000000005")!
    static let sentence = UUID(uuidString: "10000000-0000-0000-0000-000000000006")!
    static let cafeEround = UUID(uuidString: "10000000-0000-0000-0000-000000000007")!
    static let exhibition = UUID(uuidString: "10000000-0000-0000-0000-000000000008")!
}

// MARK: - 통합 Card 모델
/// 모든 탭(Home, Folder, Search, Share)에서 공유하는 통합 카드 데이터 모델
struct Card: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var summary: String
    var category: FolderCategory
    var subcategory: String
    var tags: [String]
    var fields: [String: String]
    var createdAt: Date
    var updatedAt: Date
    var thumbnailURL: String?
    var screenshotURLs: [String]
    
    // MARK: - 초기화
    init(
        id: UUID = UUID(),
        title: String,
        summary: String = "",
        category: FolderCategory,
        subcategory: String,
        tags: [String] = [],
        fields: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        thumbnailURL: String? = nil,
        screenshotURLs: [String] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.subcategory = subcategory
        self.tags = tags
        self.fields = fields
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailURL = thumbnailURL
        self.screenshotURLs = screenshotURLs
    }
    
    // ... (편의 속성: tagsString, location, dateString, thumbnailName, firstScreenshot) ...
    var tagsString: String {
        tags.isEmpty ? "" : tags.map { "#\($0)" }.joined(separator: " ")
    }
    var location: String {
        fields["주소"] ?? fields["위치"] ?? fields["장소명"] ?? fields["가게명"] ?? ""
    }
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd."
        return formatter.string(from: createdAt)
    }
    var thumbnailName: String {
        thumbnailURL ?? "placeholder"
    }
    var firstScreenshot: String? {
        screenshotURLs.first
    }
}

// MARK: - FolderCategory (대분류)
// ... (FolderCategory, FolderSubcategory enum/struct 정의는 변경 없음) ...
enum FolderCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case info = "Info"
    case contents = "Contents"
    case social = "Social"
    case log = "Log"
    case musicArt = "Music/Art"
    case etc = "Etc."

    var id: String { rawValue }
    var color: Color {
        switch self {
        case .info: return .homeGreen
        case .contents: return .homeGreenLight
        case .social: return .caplogGrayMedium
        case .log: return .brandAccent
        case .musicArt: return .brandGreenCard
        case .etc: return .brandLine
        }
    }
    var emoji: String {
        switch self {
        case .info: return "📂"
        case .contents: return "😂"
        case .social: return "💬"
        case .log: return "🎮"
        case .musicArt: return "🎵"
        case .etc: return "🎸"
        }
    }
    var subcategories: [FolderSubcategory] {
        switch self {
        case .info:
            return [
                FolderSubcategory(name: "맛집", group: "장소"),
                FolderSubcategory(name: "카페", group: "장소"),
                FolderSubcategory(name: "공부", group: "공부"),
                FolderSubcategory(name: "공고", group: "공부"),
                FolderSubcategory(name: "취업", group: "공부"),
                FolderSubcategory(name: "필기", group: "공부"),
                FolderSubcategory(name: "뉴스", group: "라이프스타일"),
                FolderSubcategory(name: "문화생활", group: "라이프스타일"),
                FolderSubcategory(name: "운동/건강", group: "라이프스타일"),
                FolderSubcategory(name: "기타", group: "라이프스타일"),
                FolderSubcategory(name: "소비", group: "소비"),
                FolderSubcategory(name: "쿠폰", group: "소비")
            ]
        // ... (다른 카테고리들) ...
        case .contents:
            return [FolderSubcategory(name: "글", group: nil), FolderSubcategory(name: "짤", group: nil)]
        case .social:
            return [FolderSubcategory(name: "채팅", group: nil), FolderSubcategory(name: "사진", group: nil)]
        case .log:
            return [FolderSubcategory(name: "기록", group: nil), FolderSubcategory(name: "활동", group: nil)]
        case .musicArt:
            return [FolderSubcategory(name: "음악", group: nil), FolderSubcategory(name: "미술", group: nil)]
        case .etc:
            return [FolderSubcategory(name: "기타", group: nil)]
        }
    }
}
struct FolderSubcategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let group: String?
    var displayGroup: String { group ?? "" }
}

// MARK: - 더미 샘플 데이터
extension Card {
    // ✅ (수정) 고정 UUID를 사용하도록 수정
    static let sampleCards: [Card] = [
        Card(
            id: MockCardIDs.starbucksCoupon,
            title: "무료 음료 쿠폰",
            summary: "스타벅스 무료 음료 1잔",
            category: .info, subcategory: "쿠폰", tags: ["스타벅스", "무료음료"],
            fields: ["브랜드": "Starbucks", "만료일": "2025. 11. 20."],
            thumbnailURL: "shot_coupon", screenshotURLs: ["shot_coupon"]
        ),
        Card(
            id: MockCardIDs.oliveYoungCoupon,
            title: "10,000원 할인권",
            summary: "올리브영 1만원 할인",
            category: .info, subcategory: "쿠폰", tags: ["올리브영", "할인"],
            fields: ["브랜드": "Olive Young", "만료일": "2025. 11. 22."],
            thumbnailURL: "placeholder", screenshotURLs: ["placeholder"]
        ),
        Card(
            id: MockCardIDs.chickenCoupon,
            title: "치킨 5,000원 할인",
            summary: "배달의민족 치킨 할인 쿠폰",
            category: .info, subcategory: "쿠폰", tags: ["배달", "치킨"],
            fields: ["브랜드": "배달의민족", "만료일": "2025. 11. 25."],
            thumbnailURL: "placeholder", screenshotURLs: ["placeholder"]
        ),
        Card(
            id: MockCardIDs.makguksu,
            title: "이목리 막국수",
            summary: "동치미막국수, 명태회막국수",
            category: .info, subcategory: "맛집", tags: ["맛집", "속초", "막국수"],
            fields: ["장소명": "이목리 막국수", "주소": "강원 속초시 이목로 104-43", "대표메뉴": "동치미막국수"],
            thumbnailURL: "이목리막국수", screenshotURLs: ["이목리막국수"]
        ),
        Card(
            id: MockCardIDs.nangman,
            title: "낭만식탁",
            summary: "사케동, 간장새우, 감성 인테리어",
            category: .info, subcategory: "맛집", tags: ["데이트", "분위기좋음", "서대문"],
            fields: ["장소명": "낭만식탁", "주소": "서울 서대문구 이화여대5길 6", "대표메뉴": "간장새우"],
            thumbnailURL: "낭만식탁", screenshotURLs: ["낭만식탁"]
        ),
        Card(
            id: MockCardIDs.sentence,
            title: "마음에 남는 문장",
            summary: "'너무 늦은 시도란 없다.'",
            category: .contents, subcategory: "글", tags: ["동기부여", "긍정"],
            fields: ["topic": "동기부여"],
            thumbnailURL: "글귀", screenshotURLs: ["글귀"]
        ),
        Card(
            id: MockCardIDs.cafeEround,
            title: "카페 이라운드",
            summary: "디저트 맛집, 감성 카페",
            category: .info, subcategory: "카페", tags: ["디저트", "감성", "연희동"],
            fields: ["장소명": "카페 이라운드", "주소": "서울 서대문구 연희동"],
            thumbnailURL: "스샷1", screenshotURLs: ["스샷1"]
        ),
        Card(
            id: MockCardIDs.exhibition,
            title: "전시회 모먼트",
            summary: "성수동 아트센터 전시",
            category: .info, subcategory: "문화생활", tags: ["주말데이트", "예술", "전시"],
            fields: ["장소명": "성수동 아트센터", "주소": "서울 성동구 성수동"],
            thumbnailURL: "스샷2", screenshotURLs: ["스샷2"]
        )
    ]
}
