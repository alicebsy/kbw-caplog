import SwiftUI

struct Register1View: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 로고 + 앱명
            VStack(spacing: 16) {
                Image("caplog_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                Text("Caplog")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }
            
            // Join / Log in
            VStack(spacing: 16) {
                NavigationLink(destination: Register2View()) {
                    Text("Join")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 343, height: 49)
                        .background(Color.registerGreen)   // Primary
                        .cornerRadius(16)
                }
                NavigationLink(destination: Register3View()) {
                    Text("Log in")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 343, height: 49)
                        .background(Color.homeGreenDark)   // Secondary(대조)
                        .cornerRadius(16)
                }
            }
            
            // 약관 안내
            Text("By joining Caplog, you agreed to our Terms of service and Privacy policy")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.brandBgTop, .brandBgBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarHidden(true)
    }
}
