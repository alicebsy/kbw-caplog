import SwiftUI
import Combine

struct Register1View: View {
    // 👇 부모 뷰(StartView)와 상태를 공유하기 위한 바인딩 변수
    @Binding var isLoggedIn: Bool
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 로고 + 앱명
            VStack(spacing: 16) {
                Image("caplog_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            }
            
            // Join / Log in
            VStack(spacing: 16) {
                NavigationLink(destination: Register2View()) {
                    Text("Join")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 343, height: 49)
                        .background(Color.joinButton)
                        .cornerRadius(16)
                }
                NavigationLink(destination: Register3View()) {
                    Text("Log in")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 343, height: 49)
                        .background(Color.loginButton)
                        .cornerRadius(16)
                }
            }
            
            // 약관 안내 (줄바꿈 위치 조정)
            Text("By joining Caplog, you agreed to\nour Terms of service and Privacy policy.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // ✅ 임시 버튼 추가 (기존 코드 영향 X)
            VStack(spacing: 12) {
                NavigationLink(destination: Register4_1View()) {
                    Text("임시 레지스터4-1")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 40)
                        .background(Color.yellow)
                        .cornerRadius(10)
                }
                NavigationLink(destination: HomeView()) {
                    Text("임시 홈")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 40)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                NavigationLink(destination: MyPageView()) {
                    Text("임시 마이페이지")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 40)
                        .background(Color.purple)
                        .cornerRadius(10)
                }
            }

            .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.brandGradientTop, .brandGradientBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
    }
}
