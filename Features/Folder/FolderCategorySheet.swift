import SwiftUI

struct FolderCategorySheet: View {
    @Binding var selectedCategory: FolderCategory
    @Binding var selectedSub: String?

    var body: some View {
        HStack {
            // 왼쪽: 메인 카테고리
            List(FolderCategory.allCases, id: \.self) { cat in
                Button {
                    selectedCategory = cat
                    selectedSub = nil
                } label: {
                    Text(cat.rawValue)
                        .font(.headline)
                        .foregroundColor(selectedCategory == cat ? .white : .brandTextMain)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(selectedCategory == cat ? cat.color : .clear)
                        .cornerRadius(8)
                }
            }
            // 오른쪽: 하위 카테고리
            List(selectedCategory.subcategories, id: \.self) { sub in
                Button {
                    selectedSub = sub
                } label: {
                    Text(sub)
                        .foregroundColor(selectedSub == sub ? .homeGreen : .brandTextMain)
                }
            }
        }
    }
}
