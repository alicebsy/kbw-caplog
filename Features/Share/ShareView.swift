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
            HStack(spacing: 10) {
                Button { innerTab = .friends } label: {
                    Label("친구", systemImage: "person.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(innerTab == .friends ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(innerTab == .friends ? Color.myPageSectionGreen : Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                Button { innerTab = .chats } label: {
                    Label("채팅", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(innerTab == .chats ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(innerTab == .chats ? Color.myPageSectionGreen : Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color(uiColor: .systemGroupedBackground))
            
            Group {
                switch innerTab {
                case .friends:
                    ShareFriendListView(vm: vm, selectedThread: $selectedThread)
                case .chats:
                    ShareChatListView(vm: vm, selectedThread: $selectedThread)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        // 대화방은 전체 화면으로 띄워 하단 탭이 보이지 않도록 처리
        .fullScreenCover(item: $selectedThread) { thread in
            NavigationStack {
                ChatRoomView(vm: vm, thread: thread)
            }
        }
        .task { await vm.loadAll() }
    }
}
