import SwiftUI

/// 하단에 커스텀 탭바(CaplogTabBar) 하나만 표시. 시스템 TabView 미사용.
struct AppNavigation: View {
    @State private var selectedTab: CaplogTab = .home

    var body: some View {
        Group {
            switch selectedTab {
            case .home:      HomeView()
            case .folder:    FolderView()
            case .search:    SearchView()
            case .share:     ShareView()
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
        }
    }
}
