import SwiftUI
#if SOCIAL_LOGIN_ENABLED
import AuthenticationServices
import GoogleSignIn
import KakaoSDKAuth
#endif

/// 로그인 화면 (이메일/비밀번호 + 소셜 로그인)
struct Register3View: View {
    @ObservedObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var goPerm = false
    @State private var isLoading = false

    private var canLogin: Bool { !email.isEmpty && !password.isEmpty && !isLoading }

    var body: some View {
        // 랜딩과 같은 배경·로고·버튼을 써서 화면이 바뀐 느낌이 나지 않게 합니다.
        // 내용이 짧으면 세로 가운데, 길어지면(키보드·소셜 버튼) 원래대로 스크롤됩니다.
        GeometryReader { proxy in
            ScrollView {
                formContent
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
            }
            .background(AuthBackground())
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var formContent: some View {
        VStack(spacing: 28) {
            AuthHeader(title: "로그인", subtitle: "저장해둔 카드를 이어서 볼 수 있어요.")

            AuthFieldGroup {
                UnderlineTextField(placeholder: "이메일", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)

                UnderlineTextField(placeholder: "비밀번호", text: $password, isSecure: true)
                    .textContentType(.password)
                    .privacySensitive(true)
            }

            // 로그인 버튼
            Button {
                guard !email.isEmpty && !password.isEmpty else {
                    return show("이메일과 비밀번호를 입력해주세요.")
                }
                isLoading = true
                Task {
                    do {
                        let session = try await AuthAPI.login(email: email, password: password)
                        SessionStore.save(
                            accessToken: session.accessToken,
                            refreshToken: session.refreshToken
                        )
                        goPerm = true
                    } catch {
                        show("로그인 실패: \(error.localizedDescription)")
                    }
                    isLoading = false
                }
            } label: {
                Text(isLoading ? "로그인 중..." : "로그인")
                    .authPrimaryButton()
            }
            .disabled(isLoading)
            .alert("로그인", isPresented: $showAlert) {
                Button("확인", role: .cancel) {}
            } message: { Text(alertMessage) }
            .navigationDestination(isPresented: $goPerm) { Register4_1View(appState: appState) }

            #if SOCIAL_LOGIN_ENABLED
            Text("또는")
                .font(.system(size: 13))
                .foregroundColor(Color.brandTextMain)

            VStack(spacing: 12) {
                // Apple
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
                            case .failure(let e):
                                show("Apple 로그인 실패: \(e.localizedDescription)")
                            }
                        }
                    }
                }

                // Google
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
                                case .failure(let e):
                                    show("Google 로그인 실패: \(e.localizedDescription)")
                                }
                            }
                        }
                    }
                }

                // Kakao
                SocialLoginButton(provider: "KakaoTalk", logo: Image("kakao_logo").resizable()) {
                    Task {
                        AuthService.shared.signInWithKakao { result in
                            switch result {
                            case .success(let token):
                                Task {
                                    await exchangeAndProceed { try await AuthAPI.exchangeKakao(accessToken: token.accessToken) }
                                }
                            case .failure(let e):
                                show("Kakao 로그인 실패: \(e.localizedDescription)")
                            }
                        }
                    }
                }
            }
            #endif

            // 아래가 텅 비어 있던 자리에 실제로 쓸모 있는 다음 행동을 둡니다.
            // ("Forgot Password?"는 밑줄까지 그어 눌리는 것처럼 보였지만
            //  아무 동작도 없는 Text였습니다. 재설정 기능이 생기면 여기에 넣어주세요.)
            AuthSwitchPrompt(question: "아직 계정이 없으신가요?", actionTitle: "회원가입") {
                Register2View(appState: appState)
            }
        }
    }

    private func show(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }

    private func exchangeAndProceed(_ call: @escaping () async throws -> AuthAPI.LoginResponse) async {
        isLoading = true
        do {
            let session = try await call()
            SessionStore.save(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
            goPerm = true
        } catch {
            show("소셜 로그인 실패: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
