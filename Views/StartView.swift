import SwiftUI

struct StartView: View {
    @State private var go = false
    @State private var hasToken = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.brandGradientTop, Color.brandGradientBottom]),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    Image("caplog_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    Spacer()
                }
            }
            .onAppear {
                if let token = SessionStore.readJWT(), !token.isEmpty {
                    hasToken = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        go = true
                    }
                } else {
                    hasToken = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        go = true
                    }
                }
            }
            .navigationDestination(isPresented: $go) {
                if hasToken {
                    // ✅ 로그인된 상태에서는 AppRootView (탭 구조)로 진입
                    AppRootView()
                } else {
                    // ✅ 로그인 안 되어 있으면 Register1View로 이동
                    Register1View()
                }
            }
        }
    }
}
