import SwiftUI
import CoreLocation

struct NotificationView: View {
    @StateObject private var loc = LocationPermission()

    private var actionTitle: String {
        switch loc.status {
        case .authorizedAlways, .authorizedWhenInUse:
            return "허용됨"
        case .denied, .restricted:
            return "설정에서 허용"
        default:
            return "허용"
        }
    }

    var body: some View {
        VStack {
            Text("알림 화면")
                .font(.title3.bold())
                .padding(.top, 80)

            Spacer()

            PermissionRow(
                title: "위치 권한",
                desc: "정확한 리마인드를 위해 위치 접근이 필요합니다.",
                actionTitle: actionTitle
            ) {
                loc.request()
            }

            Spacer()
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}
