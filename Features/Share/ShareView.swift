import SwiftUI

struct ShareView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil

    // 탭 라우팅
    @State private var goHome = false
    @State private var goFolder = false
    @State private var goSearch = false
    @State private var goMyPage = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("Share")
                        .font(.system(size: 24, weight: .bold))
                    Text("공유 화면 임시 버전입니다.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("공유")
            .navigationBarTitleDisplayMode(.inline)

            // 하단 탭
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

            // 라우팅
            .navigationDestination(isPresented: $goHome)   { HomeView() }
            .navigationDestination(isPresented: $goFolder) { FolderView() }
            .navigationDestination(isPresented: $goSearch) { SearchView() }
            .navigationDestination(isPresented: $goMyPage) { MyPageView() }
        }
    }
}
