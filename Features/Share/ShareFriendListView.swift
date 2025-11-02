import SwiftUI
import Combine

@MainActor
struct ShareFriendListView: View {
    @ObservedObject var vm: ShareViewModel   // 🔹 같은 vm 사용
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("친구 추가") { showAdd = true }
            }
        }
        .sheet(isPresented: $showAdd) { ShareFriendSearchSheet() }
    }
}
