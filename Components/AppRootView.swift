import SwiftUI

// MARK: - 네비게이션 목적지 정의
enum Route: Hashable {
    case myPage
    case detail(id: String)
}

struct AppRootView: View {
    @State private var path = NavigationPath()
    @State private var selectedTab: CaplogTab = .home

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {

                // 홈
                HomeView()
                    .tag(CaplogTab.home)
                    .tabItem { Label("Home", systemImage: "house.fill") }

                // 폴더(보관함)
                FolderView()
                    .tag(CaplogTab.folder)
                    .tabItem { Label("Folder", systemImage: "folder.fill") }

                // 검색
                SearchView { tab in selectedTab = tab }
                    .tag(CaplogTab.search)
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }

                // 공유
                ShareView { tab in selectedTab = tab }
                    .tag(CaplogTab.share)
                    .tabItem { Label("Share", systemImage: "square.and.arrow.up") }

                // 마이페이지
                MyPageView()
                    .tag(CaplogTab.mypage)
                    .tabItem { Label("My", systemImage: "person.fill") }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .myPage:
                    MyPageView().customBackButton()
                case .detail(let id):
                    Text("Detail View for \(id)").customBackButton()
                }
            }
        }
    }
}

#Preview { AppRootView() }

// MARK: - 공용 백버튼
private struct CustomBackButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
        }
        .buttonStyle(.plain)
    }
}
extension View {
    func customBackButton() -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbar { ToolbarItem(placement: .topBarLeading) { CustomBackButton() } }
    }
}
