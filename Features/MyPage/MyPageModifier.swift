import SwiftUI

struct MyPageModifier: ViewModifier {
    @ObservedObject var vm: MyPageViewModel
    @Binding var showingError: Bool
    
    @State private var showingSuccess = false

    func body(content: Self.Content) -> some View {
        content
            .background(
                Color.homeBackgroundLight
                    .ignoresSafeArea()
            )
            .navigationTitle("My Page")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: .logoutTapped)) { _ in
                Task { await vm.logout() }
            }
            .onChange(of: vm.errorMessage) { oldValue, newValue in
                print("🔔 errorMessage 변경: '\(oldValue ?? "nil")' -> '\(newValue ?? "nil")'")
                showingError = (newValue != nil)
            }
            .onChange(of: vm.successMessage) { oldValue, newValue in
                print("🔔 successMessage 변경: '\(oldValue ?? "nil")' -> '\(newValue ?? "nil")'")
                showingSuccess = (newValue != nil)
                
                if newValue != nil {
                    print("✅ showingSuccess가 true로 설정됨")
                }
            }
            .alert("오류", isPresented: $showingError) {
                Button("확인", role: .cancel) {
                    print("❌ 오류 알림 닫힘")
                    vm.errorMessage = nil
                }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .alert("성공", isPresented: $showingSuccess) {
                Button("확인", role: .cancel) {
                    print("✅ 성공 알림 닫힘")
                    vm.successMessage = nil
                }
            } message: {
                Text(vm.successMessage ?? "")
            }
    }
}

extension Notification.Name {
    static let logoutTapped = Notification.Name("logoutTapped")
}
