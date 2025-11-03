import SwiftUI

struct ShareFriendSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var results: [Friend] = []

    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 8) {
                    TextField("친구 이름 검색", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                    Button("검색") { search() }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                List(results) { f in
                    FriendRow(name: f.name)   // 상태 표시 없음
                }
                .listStyle(.plain)
            }
            .navigationTitle("친구 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func search() {
        // 목업 데이터(상태 없음)
        let all: [Friend] = [
            Friend(id: "u1", name: "민하", avatarURL: nil),
            Friend(id: "u2", name: "다혜", avatarURL: nil),
            Friend(id: "u3", name: "서연", avatarURL: nil),
            Friend(id: "u4", name: "배우", avatarURL: nil)
        ]
        let k = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        results = k.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(k) }
    }
}
