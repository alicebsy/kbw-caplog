import SwiftUI
internal import CoreLocation

struct Register4PermissionView: View {
    @StateObject private var loc  = LocationPermission()
    @StateObject private var noti = NotificationPermission()
    @State private var showPicker = false
    @State private var goMain = false

    var body: some View {
        VStack(spacing: 24) {
            Text("권한 설정").font(.system(size: 22, weight: .bold))
            
            PermissionRow(
                title: "위치 권한",
                desc: "위치 기반으로 스크린샷 정보를 리마인드합니다.",
                actionTitle: (loc.status == .authorizedWhenInUse || loc.status == .authorizedAlways) ? "허용됨" : "허용"
            ) { loc.request() }
            
            PermissionRow(
                title: "스크린샷 접근",
                desc: "스크린샷을 불러와 자동 분류를 시작합니다.",
                actionTitle: "사진 선택"
            ) { showPicker = true }
                .sheet(isPresented: $showPicker) { ScreenshotPicker() }
            
            PermissionRow(
                title: "알림 권한",
                desc: "만료 전 리마인드 알림을 전송합니다.",
                actionTitle: noti.granted ? "허용됨" : "허용"
            ) { noti.request() }
            
            Button("모두 완료") { goMain = true }
                .padding()
                .background(Color.blue.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
                .navigationDestination(isPresented: $goMain) {
                    MainView()
                }
        }
        .padding()
    }
}
