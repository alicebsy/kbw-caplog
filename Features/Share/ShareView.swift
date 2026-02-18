import SwiftUI

enum ShareInnerTab { case friends, chats }

struct ShareView: View {
    @StateObject private var vm = ShareViewModel.shared

    // 상단 내부 탭
    @State private var innerTab: ShareInnerTab = .friends
    /// 채팅방 진입용 (NavigationStack에서 동작하도록 ShareView에서 관리)
    @State private var selectedThread: ChatThread? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { innerTab = .friends } label: {
                    Label("친구", systemImage: "person.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(innerTab == .friends ? .primary : .secondary)
                        .padding(.vertical, 8).padding(.horizontal, 10)
                        .background(Capsule().fill(innerTab == .friends ? Color.secondary.opacity(0.15) : .clear))
                }
                Button { innerTab = .chats } label: {
                    Label("채팅", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(innerTab == .chats ? .primary : .secondary)
                        .padding(.vertical, 8).padding(.horizontal, 10)
                        .background(Capsule().fill(innerTab == .chats ? Color.secondary.opacity(0.15) : .clear))
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 6)
            
            Group {
                switch innerTab {
                case .friends:
                    ShareFriendListView(vm: vm, selectedThread: $selectedThread)
                case .chats:
                    ShareChatListView(vm: vm, selectedThread: $selectedThread)
                }
            }
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedThread) { thread in
            ChatRoomView(vm: vm, thread: thread)
        }
        .task { await vm.loadAll() }
    }
}
