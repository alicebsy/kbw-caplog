import SwiftUI
import Combine

@MainActor
struct ShareFriendListView: View {
    @ObservedObject var vm: ShareViewModel
    @State private var showAdd = false

    var body: some View {
        List(vm.friends) { friend in
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                Text(friend.name)
                    .font(.headline)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("친구 추가") { showAdd = true }
            }
        }
        .sheet(isPresented: $showAdd) {
            ShareFriendSearchSheet()
        }
        // 상위에서 loadAll 수행
    }
}
