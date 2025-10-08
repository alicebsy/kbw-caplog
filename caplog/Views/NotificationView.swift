//임시 파일입니다.
import SwiftUI

struct NotificationView: View {
    var body: some View {
        VStack {
            Text("알림 화면")
                .font(.title3.bold())
                .padding(.top, 80)
            Spacer()
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}
