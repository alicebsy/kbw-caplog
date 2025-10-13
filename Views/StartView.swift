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
                    Image("caplog_logo").resizable().scaledToFit().frame(width: 120, height: 120)
                    Text("Caplog").font(.system(size: 28, weight: .bold)).foregroundColor(.black)
                    Spacer()
                }
            }
            .onAppear {
                if let token = SessionStore.readJWT(), !token.isEmpty {
                    hasToken = true
                    go = true                         // 즉시 메인으로
                } else {
                    hasToken = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { go = true } // 스플래시 후 진입
                }
            }
            .navigationDestination(isPresented: $go) {
                if hasToken {
                    RegisterMainView()               // 이미 로그인된 상태
                } else {
                    Register1View()                  // 로그인/회원가입 진입
                }
            }
        }
    }
}
