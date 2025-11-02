import SwiftUI

final class ShareFriendListVM: ObservableObject {
    @Published var friends: [Friend] = []
    private let api = ShareAPI()

    @MainActor func load() async {
        do { friends = try await api.fetchFriends() }
        catch {
            friends = [
                Friend(id: "1", name: "강다혜", status: "캡스톤 파이팅!", avatarURL: nil),
                Friend(id: "2", name: "우민하", status: "Swift 천재", avatarURL: nil)
            ]
        }
    }
}

struct ShareFriendListView: View {
    @StateObject private var vm = ShareFriendListVM()
    @State private var showAdd = false

    var body: some View {
        List(vm.friends) { friend in
            HStack {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text(friend.name).font(.headline)
                    if let s = friend.status {
                        Text(s).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task { await vm.load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("친구 추가") { showAdd = true }
            }
        }
        .sheet(isPresented: $showAdd) { ShareFriendSearchSheet() }
    }
}
