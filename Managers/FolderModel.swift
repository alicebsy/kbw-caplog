import SwiftUI

enum FolderCategory: String, CaseIterable, Identifiable {
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

    var subcategories: [String] {
        switch self {
        case .info: return ["맛집", "카페", "학업/업무", "라이프스타일", "소비"]
        case .contents: return ["글", "짤"]
        case .social: return ["채팅", "사진"]
        case .log: return ["기록", "활동"]
        case .musicArt: return ["음악", "미술"]
        case .etc: return ["기타"]
        }
    }
}

struct FolderItem: Identifiable {
    let id = UUID()
    let category: FolderCategory
    let subcategory: String
    let title: String
    let description: String
    let location: String
    let date: String
    let imageName: String?
}
