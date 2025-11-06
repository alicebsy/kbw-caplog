import SwiftUI

enum ShareInnerTab { case friends, chats }

struct ShareView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = ShareViewModel(repo: MockShareRepository())

    // 하단 글로벌 탭 라우팅
    @State private var goHome = false
    @State private var goFolder = false
    @State private var goSearch = false
    @State private var goMyPage = false

    // 상단 내부 탭
    @State private var innerTab: ShareInnerTab = .chats

    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ 수정: Color(.systemBackground) 제거
                // Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // ... (이하 탭 스위처, 콘텐츠 동일) ...
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
                        case .friends: ShareFriendListView(vm: vm)
                        case .chats:   ShareChatListView(vm: vm)
                        }
                    }
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .task { await vm.loadAll() }

            // ... (이하 탭 바, NavigationDestination 동일) ...
            
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
}
