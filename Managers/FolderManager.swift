import Foundation
import Combine

final class FolderManager: ObservableObject {
    @Published var items: [FolderItem] = [
        FolderItem(category: .info, subcategory: "맛집", title: "낭만식탁", description: "사케동, 간장새우", location: "서울 서대문구 이화여대5길 6", date: "2025.10.10", imageName: nil),
        FolderItem(category: .info, subcategory: "맛집", title: "이목리 막국수", description: "동치미막국수, 명태회막국수", location: "강원 속초시 이목로 104-43", date: "2025.09.28", imageName: nil)
    ]
}
