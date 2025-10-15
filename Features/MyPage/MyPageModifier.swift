import SwiftUI

struct MyPageModifier: ViewModifier {
    @ObservedObject var vm: MyPageViewModel
    @Binding var showingError: Bool

    // 🔧 핵심 수정: Content -> Self.Content (프로젝트 내 'Content'와 이름 충돌 방지)
    func body(content: Self.Content) -> some View {
        content
            .background(
                Color.homeBackgroundLight
                    .ignoresSafeArea()
            )
            .navigationTitle("My Page")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { vm.onAppear() }
            .onReceive(NotificationCenter.default.publisher(for: .logoutTapped)) { _ in
                Task { await vm.logout() }
            }
            .onChange(of: vm.errorMessage, initial: false) { _, newValue in
                showingError = (newValue != nil)
            }
            .alert("오류", isPresented: $showingError) {
                Button("확인", role: .cancel) {
                    vm.errorMessage = nil
                }
            } message: {
                Text(vm.errorMessage ?? "")
            }
    }
}

// MARK: - Notification.Name 확장
extension Notification.Name {
    static let logoutTapped = Notification.Name("logoutTapped")
}
