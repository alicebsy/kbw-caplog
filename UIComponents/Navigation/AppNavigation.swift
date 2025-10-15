import SwiftUI

struct AppNavigation: View {
    // @State private var path = NavigationPath() // 이제 필요 없습니다.
    @State private var selectedTab: CaplogTab = .home

    var body: some View {
        // 👇 NavigationStack을 제거하고 TabView가 바로 시작됩니다.
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("홈", systemImage: "house.fill") }
                .tag(CaplogTab.home)

            FolderView()
                .tabItem { Label("폴더", systemImage: "folder.fill") }
                .tag(CaplogTab.folder)

            SearchView()
                .tabItem { Label("검색", systemImage: "magnifyingglass") }
                .tag(CaplogTab.search)

            ShareView()
                .tabItem { Label("공유", systemImage: "square.and.arrow.up.fill") }
                .tag(CaplogTab.share)

            MyPageView()
                .tabItem { Label("마이페이지", systemImage: "person.fill") }
                .tag(CaplogTab.myPage)
        }
        // 👇 navigationDestination은 이제 StartView에서 관리하므로 여기서도 제거합니다.
        // .navigationDestination(for: AppRoute.self) { ... }
    }
}
