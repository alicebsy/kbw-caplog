import SwiftUI

// MARK: - 네비게이션 목적지 정의
enum Route: Hashable {
    case myPage
    case detail(id: String)
}

// MARK: - AppRootView
struct AppRootView: View {
    @State private var path = NavigationPath()
    @State private var selectedTab: CaplogTab = .home   // 실제 enum 이름에 맞게 수정

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {

                // 홈 탭
                HomeView()
                    .tag(CaplogTab.home)
                    .tabItem { Label("Home", systemImage: "house") }

                // 마이페이지 탭
                MyPageView()
                    .tag(CaplogTab.mypage)
                    .tabItem { Label("My", systemImage: "person") }
            }

            // MARK: - 공용 네비게이션 목적지 (push 시 화면)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .myPage:
                    MyPageView()
                        .customBackButton()   // ✅ 이름 변경 → 충돌 방지

                case .detail(let id):
                    Text("Detail View for \(id)") // 임시 DetailView
                        .customBackButton()
                }
            }
        }
    }
}

#Preview {
    AppRootView()
}

// MARK: - 백버튼 구조체 & 뷰 확장 (이 파일 안에서만 유효하게)
private struct CustomBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()   // 항상 바로 전 화면으로 pop
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// 어떤 화면에도 적용 가능한 공용 백버튼
    func customBackButton() -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CustomBackButton()
                }
            }
    }
}
