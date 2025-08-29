import SwiftUI

// MARK: - App Entry
@main
struct CaplogApp: App {
    var body: some Scene {
        WindowGroup {
            Start()
        }
    }
}

// MARK: - Color Palette
extension Color {
    static let gradientTop   = Color(red: 255/255, green: 252/255, blue: 241/255) // #FFFCF1
    static let gradientBottom = Color(red: 135/255, green: 171/255, blue: 164/255) // #87ABA4

    static let joinButton  = Color(red: 170/255, green: 187/255, blue: 186/255) // #AABBBA
    static let loginButton = Color(red:  94/255, green:  88/255, blue:  88/255) // #5E5858

    static let register2Join = Color(red: 191/255, green: 194/255, blue: 195/255) // #BFC2C3
    static let checkMint     = Color(red: 150/255, green: 186/255, blue: 193/255) // #96BAC1

    static let placeholder = Color(red: 196/255, green: 196/255, blue: 198/255)   // #C4C4C6
    static let divider     = Color(red: 241/255, green: 241/255, blue: 241/255)   // #F1F1F1
}

// MARK: - Underline TextField
struct UnderlineTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.placeholder))
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.placeholder))
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }
            Divider().background(Color.divider)
        }
    }
}

// MARK: - CheckBox
struct CheckBoxView: View {
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray, lineWidth: 2)
                    if isChecked {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.checkMint)
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .frame(width: 24, height: 24)

                Text("I agree to receive newsletters and product updates from Caplog.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Social Login Button
struct SocialLoginButton: View {
    let provider: String
    let logo: Image
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                logo.frame(width: 20, height: 20)
                Text("Continue with \(provider)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(width: 311, height: 48)
        }
        .background(Color.white)
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
        )
    }
}

// MARK: - Start
struct Start: View {
    @State private var navigateToRegister1 = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.gradientTop, .gradientBottom]),
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    Image("caplog_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    Text("Caplog")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    navigateToRegister1 = true
                }
            }
            .navigationDestination(isPresented: $navigateToRegister1) {
                Register1()
            }
        }
    }
}

// MARK: - Register1
struct Register1: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            VStack(spacing: 16) {
                Image("caplog_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                Text("Caplog")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }
            VStack(spacing: 16) {
                NavigationLink(destination: Register2()) {
                    Text("Join")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 343, height: 49)
                        .background(Color.joinButton)
                        .cornerRadius(16)
                }
                NavigationLink(destination: Register3()) {
                    Text("Log in")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 343, height: 49)
                        .background(Color.loginButton)
                        .cornerRadius(16)
                }
            }
            Text("By joining Caplog, you agreed to our Terms of service and Privacy policy")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.gradientTop, .gradientBottom]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Register2 (Sign Up)
struct Register2: View {
    @State private var name = ""
    @State private var email = ""
    @State private var userId = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToMain = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("회원가입 화면")
                .font(.system(size: 22, weight: .bold))

            VStack(spacing: 20) {
                UnderlineTextField(placeholder: "Name", text: $name)
                UnderlineTextField(placeholder: "Email Address", text: $email)
                UnderlineTextField(placeholder: "ID", text: $userId)
                UnderlineTextField(placeholder: "Password", text: $password, isSecure: true)
                UnderlineTextField(placeholder: "Password Confirm", text: $confirmPassword, isSecure: true)
            }
            .padding(.horizontal, 40)

            CheckBoxView(isChecked: $agreeToTerms)
                .padding(.horizontal, 40)

            Button {
                if !agreeToTerms {
                    alertMessage = "약관에 동의해야 회원가입이 가능합니다."
                    showAlert = true
                } else if password != confirmPassword {
                    alertMessage = "비밀번호가 일치하지 않습니다."
                    showAlert = true
                } else if name.isEmpty || email.isEmpty || userId.isEmpty || password.isEmpty {
                    alertMessage = "모든 필드를 입력해주세요."
                    showAlert = true
                } else {
                    navigateToMain = true
                }
            } label: {
                Text("Join")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 311, height: 45)
                    .background(Color.register2Join)
                    .cornerRadius(32)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("회원가입"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("확인")))
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainView()
            }

            Text("OR")
                .font(.system(size: 12))
                .foregroundColor(.black)

            SocialLoginButton(provider: "Apple",
                              logo: Image(systemName: "applelogo")) {
                // TODO: Apple Sign-In
            }
            SocialLoginButton(provider: "Google",
                              logo: Image("google_logo").resizable()) {
                // TODO: Google Sign-In
            }
            SocialLoginButton(provider: "KakaoTalk",
                              logo: Image("kakao_logo").resizable()) {
                // TODO: Kakao Login
            }

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - Register3 (Login)
struct Register3: View {
    @State private var email = ""
    @State private var password = ""

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToMain = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("로그인 화면")
                .font(.system(size: 22, weight: .bold))

            VStack(spacing: 20) {
                UnderlineTextField(placeholder: "Email Address", text: $email)
                UnderlineTextField(placeholder: "Password", text: $password, isSecure: true)
            }
            .padding(.horizontal, 40)

            Button {
                if email.isEmpty || password.isEmpty {
                    alertMessage = "이메일과 비밀번호를 입력해주세요."
                    showAlert = true
                } else {
                    navigateToMain = true
                }
            } label: {
                Text("Login")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 311, height: 45)
                    .background(Color.loginButton)
                    .cornerRadius(32)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("로그인"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("확인")))
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainView()
            }

            Text("OR")
                .font(.system(size: 12))
                .foregroundColor(.black)

            SocialLoginButton(provider: "Apple",
                              logo: Image(systemName: "applelogo")) {
                // TODO: Apple Sign-In
            }
            SocialLoginButton(provider: "Google",
                              logo: Image("google_logo").resizable()) {
                // TODO: Google Sign-In
            }
            SocialLoginButton(provider: "KakaoTalk",
                              logo: Image("kakao_logo").resizable()) {
                // TODO: Kakao Login
            }

            Text("Forgot Password?")
                .font(.system(size: 14, weight: .semibold))
                .underline()
                .foregroundColor(.gray)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
}

// MARK: - Main
struct MainView: View {
    var body: some View {
        Text("메인 화면 (로그인 성공)")
            .font(.largeTitle)
            .padding()
    }
}