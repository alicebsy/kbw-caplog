import Foundation

struct Content: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var category: String
    var address: String
    var tags: String
    var thumbnail: String
    var screenshots: [String]
}

/// 더미 샘플 데이터 (테스트용)
let sampleContents: [Content] = [
    Content(
        name: "홍대 낭만식탁",
        category: "맛집",
        address: "서울 마포구 홍익로 12",
        tags: "#데이트 #분위기좋음",
        thumbnail: "낭만식탁",
        screenshots: ["낭만식탁"]
    ),
    Content(
        name: "카페 이라운드",
        category: "카페",
        address: "서울 서대문구 연희동",
        tags: "#디저트 #감성",
        thumbnail: "스샷1",
        screenshots: ["스샷1"]
    ),
    Content(
        name: "전시회 모먼트",
        category: "전시/문화",
        address: "성수동 아트센터",
        tags: "#주말데이트 #예술",
        thumbnail: "스샷2",
        screenshots: ["스샷2"]
    )
]
