import SwiftUI

struct SearchView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil

    // 탭 라우팅
    @State private var goHome = false
    @State private var goFolder = false
    @State private var goShare  = false
    @State private var goMyPage = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("Search")
                        .font(.system(size: 24, weight: .bold))
                    Text("검색 화면 임시 버전입니다.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("검색")
            .navigationBarTitleDisplayMode(.inline)

            // 하단 탭
            .safeAreaInset(edge: .bottom) {
                CaplogTabBar(selected: .search) { tab in
                    onSelectTab?(tab)
                    switch tab {
                    case .home:   goHome   = true
                    case .folder: goFolder = true
                    case .share:  goShare  = true
                    case .myPage: goMyPage = true
                    case .search: break
                    }
                }
            }

            // 라우팅
            .navigationDestination(isPresented: $goHome)   { HomeView() }
            .navigationDestination(isPresented: $goFolder) { FolderView() }
            .navigationDestination(isPresented: $goShare)  { ShareView() }
            .navigationDestination(isPresented: $goMyPage) { MyPageView() }
        }
    }
}
