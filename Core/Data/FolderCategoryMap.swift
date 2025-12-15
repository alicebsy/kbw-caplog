import Foundation

/// 폴더 탭에서 선택된 (대분류, 소분류)를 검색 토큰으로 변환
enum FolderCategoryMap {
    /// 서버 검색 쿼리에서 사용할 키워드(또는 태그)로 매핑
    static func tokens(for pair: CategoryPair) -> [String] {
        switch (pair.major, pair.sub) {
        // 학습
        case (.study, .lecture):    return ["lecture","class","강의","노트"]
        case (.study, .assignment): return ["assignment","과제","report","hw"]
        case (.study, .exam):       return ["exam","시험","quiz","pastpaper"]

        // 일정
        case (.schedule, .appointment): return ["appointment","약속","일정"]
        case (.schedule, .ticket):      return ["ticket","예매","입장권","티켓"]
        case (.schedule, .travel):      return ["travel","여행","예약","boarding"]

        // 쇼핑
        case (.shopping, .receipt):  return ["receipt","영수증","구매내역"]
        case (.shopping, .wishlist): return ["wishlist","장바구니","관심"]
        case (.shopping, .coupon):   return ["coupon","쿠폰","바코드"]

        // 문서
        case (.document, .idCard):      return ["id","학생증","신분증"]
        case (.document, .contract):    return ["contract","계약","약정"]
        case (.document, .certificate): return ["certificate","증명서","자격"]

        // 기타/미정
        default: return []
        }
    }
}
