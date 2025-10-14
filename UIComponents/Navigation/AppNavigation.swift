import SwiftUI

// 전역 라우트 정의 — 이 파일에서만 정의(중복 금지)
enum AppRoute: Hashable {
    case home
    case folder
    case search
    case share
    case myPage           // 라우트에도 myPage 유지
    case register
    case detail(id: String)
}

// 앱 루트 컨테이너 — TabView + NavigationStack
struct AppNavigation: View {
    @State private var path = NavigationPath()
    @State private var selectedTab: CaplogTab = .home

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                // MARK: - Home
                HomeView()
                    .tabItem { Label("홈", systemImage: "house.fill") }
                    .tag(CaplogTab.home)

                // MARK: - Folder
                FolderView()
                    .tabItem { Label("폴더", systemImage: "folder.fill") }
                    .tag(CaplogTab.folder)

                // MARK: - Search
                SearchView()
                    .tabItem { Label("검색", systemImage: "magnifyingglass") }
                    .tag(CaplogTab.search)

                // MARK: - Share
                ShareView()
                    .tabItem { Label("공유", systemImage: "square.and.arrow.up.fill") }
                    .tag(CaplogTab.share)

                // MARK: - MyPage
                MyPageView()
                    .tabItem { Label("마이페이지", systemImage: "person.fill") }
                    .tag(CaplogTab.myPage)   // ⬅︎ CaplogTab과 정확히 일치시켜야 함
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .home:     HomeView()
                case .folder:   FolderView()
                case .search:   SearchView()
                case .share:    ShareView()
                case .myPage:   MyPageView()
                case .register: RegisterMainView()
                case .detail(let id):
                    HomeContentDetailView(id: id)
                }
            }
        }
    }
}
