import SwiftUI

struct FolderAddSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var categoryName = ""
    @State private var sub1 = ""
    @State private var sub2 = ""

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("카테고리 추가")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                TextField("카테고리 이름을 입력하세요", text: $categoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("세부 카테고리1", text: $sub1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("세부 카테고리2", text: $sub2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)

            Button("추가하기") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.homeGreen)
        }
        .padding(.vertical)
        .background(Color.white)
        .cornerRadius(15)
        .presentationDetents([.medium])
    }
}
