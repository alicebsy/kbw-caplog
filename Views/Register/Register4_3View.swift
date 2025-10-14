import SwiftUI

struct Register4_3View: View {
    @StateObject private var noti = NotificationPermission()
    @State private var goMain = false

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text("알림 권한")
                    .font(.system(size: 22, weight: .bold))
                Text("유효기간 전 리마인드를 전송합니다.")
                    .foregroundStyle(.secondary)
                PermissionRow(
                    title: "알림 권한",
                    desc: "만료 전, 위치·시간에 맞춰 알림을 전송합니다.",
                    actionTitle: noti.granted ? "허용됨" : "허용"
                ) {
                    noti.request()
                }
                Button("모두 완료") { goMain = true }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!noti.granted)
                    .navigationDestination(isPresented: $goMain) {
                        RegisterMainView()
                    }
            }
            .padding()
            .padding(.bottom, 40)
            Spacer()
        }
    }
}
