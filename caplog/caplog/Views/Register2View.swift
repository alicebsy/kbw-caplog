import SwiftUI

struct Register2View: View {
    @State private var name = ""
    @State private var email = ""
    @State private var userId = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var goPerm = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("회원가입 화면").font(.system(size: 22, weight: .bold))

            VStack(spacing: 20) {
                UnderlineTextField(placeholder: "Name", text: $name)
                UnderlineTextField(placeholder: "Email Address", text: $email)
                UnderlineTextField(placeholder: "ID", text: $userId)
                UnderlineTextField(placeholder: "Password", text: $password, isSecure: true)
                UnderlineTextField(placeholder: "Password Confirm", text: $confirmPassword, isSecure: true)
            }.padding(.horizontal, 40)

            CheckBoxView(isChecked: $agreeToTerms).padding(.horizontal, 40)

            Button {
                if !agreeToTerms {
                    alertMessage = "약관에 동의해야 회원가입이 가능합니다."; showAlert = true
                } else if password != confirmPassword {
                    alertMessage = "비밀번호가 일치하지 않습니다."; showAlert = true
                } else if [name,email,userId,password].contains(where: { $0.isEmpty }) {
                    alertMessage = "모든 필드를 입력해주세요."; showAlert = true
                } else { goPerm = true }
            } label: {
                Text("Join").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(width: 311, height: 45).background(Color.register2Join).cornerRadius(32)
            }
            .alert("회원가입", isPresented: $showAlert) { Button("확인", role: .cancel) {} } message: { Text(alertMessage) }
            .navigationDestination(isPresented: $goPerm) { Register4PermissionView() }

            Text("OR").font(.system(size: 12)).foregroundColor(.black)

            SocialLoginButton(provider: "Apple",  logo: Image(systemName: "applelogo")) {}
            SocialLoginButton(provider: "Google", logo: Image("google_logo").resizable()) {}
            SocialLoginButton(provider: "KakaoTalk", logo: Image("kakao_logo").resizable()) {}

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
