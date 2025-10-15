import SwiftUI

// MARK: - 대분류
enum FolderCategory: String, CaseIterable, Identifiable {
    case info = "Info"
    case contents = "Contents"
    case social = "Social"
    case log = "Log"
    case musicArt = "Music/Art"
    case etc = "Etc."

    var id: String { rawValue }

    /// Figma 색상 톤 (카드 배경)
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

    /// 이모지 (첫 화면 카드에 표시)
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

    /// 하위 서브카테고리 (피그마 기준)
    var subcategories: [FolderSubcategory] {
        switch self {
        case .info:
            return [
                FolderSubcategory(name: "맛집", group: "장소"),
                FolderSubcategory(name: "카페", group: "장소"),
                FolderSubcategory(name: "공부/학업", group: "학업/업무"),
                FolderSubcategory(name: "공고", group: "학업/업무"),
                FolderSubcategory(name: "취업", group: "학업/업무"),
                FolderSubcategory(name: "필기", group: "학업/업무"),
                FolderSubcategory(name: "뉴스", group: "라이프스타일"),
                FolderSubcategory(name: "문화생활", group: "라이프스타일"),
                FolderSubcategory(name: "운동/건강", group: "라이프스타일"),
                FolderSubcategory(name: "기타", group: "라이프스타일"),
                FolderSubcategory(name: "소비", group: "소비")
            ]
        case .contents:
            return [
                FolderSubcategory(name: "글", group: nil),
                FolderSubcategory(name: "짤", group: nil)
            ]
        case .social:
            return [
                FolderSubcategory(name: "채팅", group: nil),
                FolderSubcategory(name: "사진", group: nil)
            ]
        case .log:
            return [
                FolderSubcategory(name: "기록", group: nil),
                FolderSubcategory(name: "활동", group: nil)
            ]
        case .musicArt:
            return [
                FolderSubcategory(name: "음악", group: nil),
                FolderSubcategory(name: "미술", group: nil)
            ]
        case .etc:
            return [
                FolderSubcategory(name: "기타", group: nil)
            ]
        }
    }
}

// MARK: - 서브카테고리
struct FolderSubcategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let group: String?
    var displayGroup: String { group ?? "" }
}

// MARK: - 아이템 (카테고리별로 세부 필드 구조)
struct FolderItem: Identifiable {
    let id = UUID()
    let category: FolderCategory
    let subcategory: String

    // 공통 필드
    let title: String
    let summary: String
    let fields: [String: String]   // 카테고리별 상세 (ex: 장소명, 주소 등)
    let date: String
    let imageName: String?

    // ✅ 호환용 프로퍼티 (중복 제거 + 안전 이름)
    var desc: String { summary }   // description → desc 로 교체
    var locationText: String {     // 기존 location과 이름 다르게
        fields["주소"] ??
        fields["위치"] ??
        fields["장소명"] ??
        fields["가게명"] ??
        ""
    }
    var imageNameResolved: String { imageName ?? "placeholder" }
}

