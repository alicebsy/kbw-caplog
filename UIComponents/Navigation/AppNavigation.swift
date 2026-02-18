import SwiftUI

/// 하단에 커스텀 탭바(CaplogTabBar) 하나만 표시. 시스템 TabView 미사용.
struct AppNavigation: View {
    @State private var selectedTab: CaplogTab = .home

    var body: some View {
        Group {
            switch selectedTab {
            case .home:      NavigationStack { HomeView() }
            case .folder:    FolderView()
            case .search:    NavigationStack { SearchView() }
            case .share:     NavigationStack { ShareView() }
            case .myPage:    MyPageView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CaplogTabBar(selected: selectedTab) { selectedTab = $0 }
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .myPage {
                NotificationCenter.default.post(name: .myPageTabSelected, object: nil)
            }
            if newValue == .home {
                NotificationCenter.default.post(name: .homeTabSelected, object: nil)
            }
        }
    }
}

extension Notification.Name {
    /// 홈 탭 선택 시 → 목록 갱신해서 새 스크린샷 카드 반영
    static let homeTabSelected = Notification.Name("homeTabSelected")
}
