import SwiftUI

enum ShareInnerTab { case friends, chats }

struct ShareView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil
    
    // ✅ (수정) 싱글톤 ViewModel 사용
    @StateObject private var vm = ShareViewModel.shared

    // 하단 글로벌 탭 라우팅
    @State private var goHome = false
    @State private var goFolder = false
    @State private var goSearch = false
    @State private var goMyPage = false

    // 상단 내부 탭
    @State private var innerTab: ShareInnerTab = .friends

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
                    ShareFriendListView(vm: vm)
                case .chats:
                    ShareChatListView(vm: vm)
                }
            }
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        
        .task { await vm.loadAll() }
        
        .safeAreaInset(edge: .bottom) {
            CaplogTabBar(selected: .share) { tab in
                onSelectTab?(tab)
                switch tab {
                case .home:   goHome   = true
                case .folder: goFolder = true
                case .search: goSearch = true
                case .myPage: goMyPage = true
                case .share:  break
                }
            }
        }
        .navigationDestination(isPresented: $goHome)   { HomeView() }
        .navigationDestination(isPresented: $goFolder) { FolderView() }
        .navigationDestination(isPresented: $goSearch) { SearchView() }
        .navigationDestination(isPresented: $goMyPage) { MyPageView() }
    }
}
