import SwiftUI

struct FolderCategorySheet: View {
    @Binding var selectedCategory: FolderCategory
    @Binding var selectedSub: String?   // 소분류 이름(String)만 저장

    var body: some View {
        HStack(spacing: 0) {
            // 왼쪽: 메인 카테고리 리스트
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
                .listRowInsets(EdgeInsets()) // 여백 최소화
            }

            // 오른쪽: 선택된 대분류의 하위 카테고리 리스트
            List(selectedCategory.subcategories, id: \.id) { sub in
                Button {
                    selectedSub = sub.name   // ✅ sub.name만 저장 (String)
                } label: {
                    Text(sub.name)
                        .font(.system(size: 16))
                        .foregroundColor(selectedSub == sub.name ? .homeGreen : .brandTextMain)
                        .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets())
            }
        }
    }
}
