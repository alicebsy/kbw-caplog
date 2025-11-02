import SwiftUI

struct ShareFriendSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField("이름 또는 ID 검색", text: $keyword)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                Spacer()
                Button("닫기") { dismiss() }
            }
            .navigationTitle("친구 추가")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
