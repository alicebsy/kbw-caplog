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
                    actionTitle: noti.actionTitle
                ) {
                    switch noti.status {
                    case .notDetermined: noti.request()
                    case .denied:        noti.openSettings()
                    case .authorized:    break
                    }
                }

                // ✅ 숨김 NavigationLink 제거

                Button("모두 완료") { goMain = true }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(noti.isAuthorized ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!noti.isAuthorized)
                    .padding(.bottom, 40)
            }
            .padding()
            Spacer()
        }
        .onAppear { noti.refresh() }
        // ✅ iOS 17+ 신 API: isPresented로 목적지 푸시
        .navigationDestination(isPresented: $goMain) {
            HomeView()
        }
    }
}
