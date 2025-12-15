import Foundation

struct CategoryGroup: Decodable {
    let name: String
    let children: [String: String]
}

// 탭("정보", "일정", "학습")별로 카테고리 묶음을 가진 구조
typealias TabCategoryMap = [String: [String: CategoryGroup]]
