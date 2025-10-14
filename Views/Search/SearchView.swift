import SwiftUI

struct SearchView: View {
    var onSelectTab: (CaplogTab) -> Void   // ✅ 기존 라우팅 함수 주입
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
        }
        .safeAreaInset(edge: .bottom) {
            CaplogTabBar(selected: .search, onSelect: onSelectTab)
        }
    }
}
