import SwiftUI
import AuthenticationServices
import GoogleSignIn
import KakaoSDKAuth

struct Register3View: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var goPerm = false
    @State private var isLoading = false

    private var canLogin: Bool { !email.isEmpty && !password.isEmpty && !isLoading }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 12)

                Text("로그인")
                    .font(.system(size: 22, weight: .bold))

                VStack(spacing: 20) {
                    UnderlineTextField(placeholder: "Email Address", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)

                    UnderlineTextField(placeholder: "Password", text: $password, isSecure: true)
                        .textContentType(.password)
                        .privacySensitive(true)
                }
                .padding(.horizontal, 40)

                Button {
                    guard !email.isEmpty && !password.isEmpty else {
                        return show("이메일과 비밀번호를 입력해주세요.")
                    }
                    isLoading = true
                    Task {
                        do {
                            let jwt = try await AuthAPI.login(email: email, password: password)
                            SessionStore.saveJWT(jwt)
                            goPerm = true
                        } catch {
                            show("로그인 실패: \(error.localizedDescription)")
                        }
                        isLoading = false
                    }
                } label: {
                    Text(isLoading ? "Logging in..." : "Login")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 311, height: 45)
                        .background(Color.loginButton)
                        .cornerRadius(32)
                        .opacity(canLogin ? 1.0 : 0.6)
                }
                .disabled(!canLogin)
                .alert("로그인", isPresented: $showAlert) {
                    Button("확인", role: .cancel) {}
                } message: { Text(alertMessage) }
                .navigationDestination(isPresented: $goPerm) { Register4_1View() }

                Text("OR")
                    .font(.system(size: 12))
                    .foregroundColor(.black)

                SocialLoginButton(provider: "Apple", logo: Image(systemName: "applelogo")) {
                    Task {
                        AuthService.shared.signInWithApple { result in
                            switch result {
                            case .success(let cred):
                                Task {
                                    guard let data = cred.identityToken,
                                          let idToken = String(data: data, encoding: .utf8) else {
                                        show("Apple 토큰 획득 실패"); return
                                    }
                                    await exchangeAndProceed { try await AuthAPI.exchangeApple(idToken: idToken) }
                                }
                            case .failure(let e): show("Apple 로그인 실패: \(e.localizedDescription)")
                            }
                        }
                    }
                }

                SocialLoginButton(provider: "Google", logo: Image("google_logo").resizable()) {
                    if let vc = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                        Task {
                            AuthService.shared.signInWithGoogle(presenting: vc) { result in
                                switch result {
                                case .success(let user):
                                    Task {
                                        guard let idToken = user.idToken?.tokenString else {
                                            show("Google 토큰 획득 실패"); return
                                        }
                                        await exchangeAndProceed { try await AuthAPI.exchangeGoogle(idToken: idToken) }
                                    }
                                case .failure(let e): show("Google 로그인 실패: \(e.localizedDescription)")
                                }
                            }
                        }
                    }
                }

                SocialLoginButton(provider: "KakaoTalk", logo: Image("kakao_logo").resizable()) {
                    Task {
                        AuthService.shared.signInWithKakao { result in
                            switch result {
                            case .success(let token):
                                Task {
                                    await exchangeAndProceed { try await AuthAPI.exchangeKakao(accessToken: token.accessToken) }
                                }
                            case .failure(let e): show("Kakao 로그인 실패: \(e.localizedDescription)")
                            }
                        }
                    }
                }

                Text("Forgot Password?")
                    .font(.system(size: 14, weight: .semibold))
                    .underline()
                    .foregroundColor(.gray)

                Spacer(minLength: 24)
            }
            .padding(.vertical, 16)
        }
        .background(Color.white.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .scrollDismissesKeyboard(.interactively)
    }

    private func show(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }

    private func exchangeAndProceed(_ call: @escaping () async throws -> String) async {
        isLoading = true
        do {
            let jwt = try await call()
            SessionStore.saveJWT(jwt)
            goPerm = true
        } catch {
            show("소셜 로그인 실패: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
