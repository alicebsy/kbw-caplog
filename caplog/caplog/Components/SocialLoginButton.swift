import SwiftUI

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
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
    }
}
