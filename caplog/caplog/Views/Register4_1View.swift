import SwiftUI
import CoreLocation

struct Register4_1View: View {
    @StateObject private var loc = LocationPermission()
    @State private var goNext = false

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text("위치 권한")
                    .font(.system(size: 22, weight: .bold))
                Text("위치 기반으로 스크린샷 정보를 리마인드합니다.")
                    .foregroundStyle(.secondary)
                PermissionRow(
                    title: "위치 권한",
                    desc: "정확한 리마인드를 위해 위치 접근이 필요합니다.",
                    actionTitle: (loc.status == .authorizedAlways || loc.status == .authorizedWhenInUse)
                        ? "허용됨" : "허용"
                ) {
                    loc.request()
                }
                Button("다음") { goNext = true }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!(loc.status == .authorizedAlways || loc.status == .authorizedWhenInUse))
                    .navigationDestination(isPresented: $goNext) {
                        Register4_2View()
                    }
            }
            .padding()
            .padding(.bottom, 40) // 중앙보다 살짝 위로 이동
            Spacer()
        }
    }
}
