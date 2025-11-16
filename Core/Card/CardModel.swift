import Foundation
import SwiftUI

// MARK: - (추가) 목업 카드용 고정 UUID
struct MockCardIDs {
    static let starbucksCoupon = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    static let megacoffeeCoupon = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
    static let emart24Coupon = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
    static let kakaopayCoupon = UUID(uuidString: "10000000-0000-0000-0000-000000000004")!
    static let pepperoCoupon = UUID(uuidString: "10000000-0000-0000-0000-000000000005")!
    static let makguksu = UUID(uuidString: "10000000-0000-0000-0000-000000000006")!
    static let nangman = UUID(uuidString: "10000000-0000-0000-0000-000000000007")!
    static let sentence = UUID(uuidString: "10000000-0000-0000-0000-000000000008")!
    static let cafeEround = UUID(uuidString: "10000000-0000-0000-0000-000000000009")!
    static let exhibition = UUID(uuidString: "10000000-0000-0000-0000-000000000010")!
    // ✅ 새 맛집 추가
    static let mokwhabanjeom = UUID(uuidString: "10000000-0000-0000-0000-000000000011")!
    static let donkatsu = UUID(uuidString: "10000000-0000-0000-0000-000000000012")!
    static let acornstol = UUID(uuidString: "10000000-0000-0000-0000-000000000013")!
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
    
    // ✅ (수정) 요청하신 이모지로 재변경
    var subcategoryEmoji: String {
        switch subcategory {
        // Info (📂)
        case "맛집": return "🍽️"
        case "카페": return "☕️"
        case "공부": return "📚"
        case "공고": return "📢"
        case "취업": return "💼"
        case "필기": return "📝"
        case "뉴스": return "📰"
        case "문화생활": return "🖼️"
        case "운동/건강": return "🏃"
        case "소비": return "💳"
        case "쿠폰": return "🏷️"
        // Contents (😂)
        case "글": return "✍️"
        case "짤": return "😆"
        // Social (👥)
        case "채팅": return "💬"
        case "사진": return "📷"
        // Log (🎮)
        case "기록": return "📓"
        case "활동": return "🌟"
        // Music/Art (🎵)
        case "음악": return "🎧"
        case "미술": return "🎨" // 수정 (🖌️ -> 🎨)
        // Etc (🎸)
        case "기타": return "❓"
        // 그 외의 경우
        default:
            return "❓"
        }
    }
    
    // ✅ (수정) 변수명 및 로직 변경 (쿠폰 -> 만료일, 그외 -> 위치)
    var contextualInfoText: String {
        // 1. 쿠폰인 경우 "만료일"
        if self.subcategory == "쿠폰" {
            return fields["만료일"] ?? ""
        }
        
        // 2. 그 외에는 "위치" (location이 알아서 "" 반환)
        return self.location
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
        case .social: return "👥" // ✅ 수정 (💬 -> 👥)
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
        // ✅ (수정) 오타 수정 (name:t: -> name:)
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
        // ✅ 쿠폰 5개
        Card(
            id: MockCardIDs.starbucksCoupon,
            title: "무료 음료 쿠폰",
            summary: "스타벅스 무료 음료 1잔",
            category: .info, subcategory: "쿠폰", tags: ["스타벅스", "무료음료"],
            fields: ["브랜드": "Starbucks", "만료일": "2025. 11. 19."],
            thumbnailURL: "스타벅스", screenshotURLs: ["스타벅스"]
        ),
        Card(
            id: MockCardIDs.megacoffeeCoupon,
            title: "(ICE)아메리카노",
            summary: "메가MGC커피 아이스 아메리카노",
            category: .info, subcategory: "쿠폰", tags: ["메가커피", "아메리카노", "무료음료"],
            fields: ["브랜드": "메가MGC커피", "만료일": "2025. 11. 30.", "바코드": "2639 3823"],
            thumbnailURL: "메가커피", screenshotURLs: ["메가커피"]
        ),
        Card(
            id: MockCardIDs.emart24Coupon,
            title: "이마트24 5천원권",
            summary: "이마트24 모바일 금액권 5,000원",
            category: .info, subcategory: "쿠폰", tags: ["이마트24", "편의점", "금액권"],
            fields: ["브랜드": "이마트24", "금액": "5,000원", "만료일": "2025. 11. 20.", "바코드": "3300 0414 5162 0790 51"],
            thumbnailURL: "이마트24", screenshotURLs: ["이마트24"]
        ),
        Card(
            id: MockCardIDs.kakaopayCoupon,
            title: "카카오페이 포인트 30,000P",
            summary: "카카오페이 포인트 3만원",
            category: .info, subcategory: "쿠폰", tags: ["카카오페이", "포인트", "GS25"],
            fields: ["브랜드": "카카오페이", "금액": "30,000P", "만료일": "2025. 11. 26.", "사용처": "카카오페이포인트", "바코드": "GS01-0986-2109-6770"],
            thumbnailURL: "카카오페이", screenshotURLs: ["카카오페이"]
        ),
        Card(
            id: MockCardIDs.pepperoCoupon,
            title: "롯데 크런키 빼빼로(지함)",
            summary: "GS25 롯데 크런키 빼빼로",
            category: .info, subcategory: "쿠폰", tags: ["빼빼로", "편의점", "GS25"],
            fields: ["브랜드": "GS25", "상품": "롯데)크런키|빼빼로(지함)", "만료일": "2025. 12. 11.", "바코드": "1324 3704 9093 8908"],
            thumbnailURL: "빼빼로", screenshotURLs: ["빼빼로"]
        ),
        // ✅ 맛집 카드들
        Card(
            id: MockCardIDs.nangman,
            title: "낭만식탁",
            summary: "사케동, 간장새우, 감성 인테리어",
            category: .info, subcategory: "맛집", tags: ["데이트", "분위기좋음", "서대문"],
            fields: ["장소명": "낭만식탁", "주소": "서울 서대문구 이화여대5길 6", "대표메뉴": "간장새우"],
            thumbnailURL: "낭만식탁", screenshotURLs: ["낭만식탁"]
        ),
        Card(
            id: MockCardIDs.mokwhabanjeom,
            title: "목화반점",
            summary: "옛날탕수육, 간짜장",
            category: .info, subcategory: "맛집", tags: ["중식", "탕수육", "간짜장"],
            fields: ["장소명": "목화반점", "주소": "충남 아산시 읍내동 151-3", "영업시간": "11:00~18:00 (월요일 휴무)", "대표메뉴": "옛날탕수육"],
            thumbnailURL: "목화반점", screenshotURLs: ["목화반점"]
        ),
        Card(
            id: MockCardIDs.donkatsu,
            title: "사장님돈까스",
            summary: "고구마치즈돈까스, 정식돈까스",
            category: .info, subcategory: "맛집", tags: ["돈까스", "이대맛집", "대현동"],
            fields: ["장소명": "사장님돈까스", "주소": "서울 서대문구 이화여대7길 11", "대표메뉴": "고구마치즈돈까스"],
            thumbnailURL: "사장님돈까스", screenshotURLs: ["사장님돈까스"]
        ),
        Card(
            id: MockCardIDs.acornstol,
            title: "아콘스톨",
            summary: "김밥, 떡볶이 맛집",
            category: .info, subcategory: "맛집", tags: ["김밥", "떡볶이", "이대맛집", "신촌"],
            fields: ["장소명": "아콘스톨", "주소": "서울 서대문구 신촌역로 17 1층 110호", "대표메뉴": "김밥"],
            thumbnailURL: "아콘스톨", screenshotURLs: ["아콘스톨"]
        ),
        Card(
            id: MockCardIDs.makguksu,
            title: "이목리막국수",
            summary: "감자전의 바삭함과 쫄쫄함의 조화",
            category: .info, subcategory: "맛집", tags: ["막국수", "맛집", "속초", "감자전"],
            fields: ["장소명": "이목리막국수", "주소": "강원 속초시", "리뷰": "1,928개", "대표메뉴": "막국수"],
            thumbnailURL: "이목리막국수", screenshotURLs: ["이목리막국수"]
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
