import Foundation
import Combine

final class FolderManager: ObservableObject {
    @Published var items: [FolderItem] = [
        FolderItem(
            category: .info,
            subcategory: "맛집",
            title: "이목리 막국수",
            summary: "동치미막국수, 명태회막국수",
            fields: [
                "장소명": "이목리 막국수",
                "주소": "강원 속초시 이목로 104-43",
                "대표메뉴": "동치미막국수",
                "유효기간": "-"
            ],
            date: "2025.09.28",
            imageName: "이목리막국수"
        ),
        FolderItem(
            category: .info,
            subcategory: "카페",
            title: "낭만식탁",
            summary: "사케동, 간장새우, 감성 인테리어",
            fields: [
                "장소명": "낭만식탁",
                "주소": "서울 서대문구 이화여대5길 6",
                "대표메뉴": "간장새우",
                "유효기간": "-"
            ],
            date: "2025.10.10",
            imageName: "낭만식탁"
        ),
        FolderItem(
            category: .contents,
            subcategory: "글",
            title: "마음에 남는 문장",
            summary: "‘너무 늦은 시도란 없다.’",
            fields: ["topic": "동기부여", "tone": "긍정적"],
            date: "2025.09.05",
            imageName: "글귀"
        )
    ]
}
