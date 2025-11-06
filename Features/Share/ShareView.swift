import SwiftUI

enum ShareInnerTab { case friends, chats }

struct ShareView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil
    
    // 🚨 @Environment(\.dismiss)는 더 이상 필요하지 않을 수 있습니다.
    // @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = ShareViewModel(repo: MockShareRepository())

    // 하단 글로벌 탭 라우팅
    @State private var goHome = false
    @State private var goFolder = false
    @State private var goSearch = false
    @State private var goMyPage = false

    // 상단 내부 탭
    @State private var innerTab: ShareInnerTab = .friends // ✅ 1. 초기 탭 수정

    var body: some View {
        // ❌ NavigationStack { ... } 제거
        
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
        // ✅ 이 View가 AppRootView의 NavigationStack에 의해 표시될 때 제목을 설정합니다.
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        
        // ✅ 2. 문제의 원인이었던 커스텀 '뒤로가기' 툴바 제거
        /*
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        */
        .task { await vm.loadAll() }
        
        // 🚨 참고: AppRootView에서 이미 TabView를 사용 중인데,
        //    여기서 CaplogTabBar를 또 safeAreaInset으로 추가하고 있습니다.
        //    현재 네비게이션 문제와는 별개지만, 탭바가 2개 생길 수 있습니다.
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
        
        // ❌ .navigationBarBackButtonHidden(true) 제거
    }
}
