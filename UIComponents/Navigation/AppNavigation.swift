import SwiftUI

struct AppNavigation: View {
    @State private var selectedTab: CaplogTab = .home

    var body: some View {
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
    }
}
