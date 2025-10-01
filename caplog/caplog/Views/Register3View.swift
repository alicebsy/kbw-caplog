import SwiftUI

struct Register3View: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var goPerm = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("로그인 화면").font(.system(size: 22, weight: .bold))

            VStack(spacing: 20) {
                UnderlineTextField(placeholder: "Email Address", text: $email)
                UnderlineTextField(placeholder: "Password", text: $password, isSecure: true)
            }.padding(.horizontal, 40)

            Button {
                if email.isEmpty || password.isEmpty {
                    alertMessage = "이메일과 비밀번호를 입력해주세요."; showAlert = true
                } else { goPerm = true }
            } label: {
                Text("Login").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(width: 311, height: 45).background(Color.loginButton).cornerRadius(32)
            }
            .alert("로그인", isPresented: $showAlert) { Button("확인", role: .cancel) {} } message: { Text(alertMessage) }
            .navigationDestination(isPresented: $goPerm) { Register4PermissionView() }

            Text("OR").font(.system(size: 12)).foregroundColor(.black)

            SocialLoginButton(provider: "Apple",  logo: Image(systemName: "applelogo")) {}
            SocialLoginButton(provider: "Google", logo: Image("google_logo").resizable()) {}
            SocialLoginButton(provider: "KakaoTalk", logo: Image("kakao_logo").resizable()) {}

            Text("Forgot Password?").font(.system(size: 14, weight: .semibold)).underline().foregroundColor(.gray)
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
