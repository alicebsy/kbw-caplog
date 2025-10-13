import SwiftUI

struct Register1View: View {
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
                gradient: Gradient(colors: [.gradientTop, .gradientBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
