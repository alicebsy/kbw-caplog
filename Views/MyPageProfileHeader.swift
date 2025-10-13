import SwiftUI

struct MyPageProfileHeader: View {
    let displayName: String
    let email: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.05))
                .frame(width: 56, height: 56)
                .overlay(Text("👤").font(.system(size: 24)))
            VStack(alignment: .leading, spacing: 4) {
                Text("\(displayName) 님").font(.system(size: 22, weight: .bold))
                Text(email).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Spacer()
            // 로그아웃 버튼
            CapsuleButton(title: "로그아웃") { NotificationCenter.default.post(name: .logoutTapped, object: nil) }
        }
        .padding(.horizontal, 20).padding(.top, 8)
    }
}

extension Notification.Name { static let logoutTapped = Notification.Name("logoutTapped") }
