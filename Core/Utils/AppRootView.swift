import SwiftUI

// MARK: - 네비게이션 목적지 정의
enum Route: Hashable {
    case myPage
    case detail(id: String)
}

/// 프리뷰/테스트용. 실제 앱 메인은 StartView → AppNavigation 사용.
struct AppRootView: View {
    var body: some View {
        AppNavigation()
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
