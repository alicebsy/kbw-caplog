import Foundation

/// 폴더의 대분류
enum MajorCategory: String, CaseIterable, Codable, Hashable {
    case study = "학습"
    case schedule = "일정"
    case shopping = "쇼핑"
    case document = "문서"
    case etc = "기타"
}

/// 폴더의 소분류
enum SubCategory: String, CaseIterable, Codable, Hashable {
    // 학습
    case lecture, assignment, exam
    // 일정
    case appointment, ticket, travel
    // 쇼핑
    case receipt, wishlist, coupon
    // 문서
    case idCard, contract, certificate
    // 기타
    case unknown
}

/// 대분류-소분류 한 쌍
struct CategoryPair: Hashable, Codable {
    let major: MajorCategory
    let sub: SubCategory
}
