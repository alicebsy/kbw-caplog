import SwiftUI

// MARK: - 설정 섹션
struct MyPageSettingsSection: View {
    @Binding var allowLocationRecommend: Bool
    @Binding var allowNotification: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "설정")

            ToggleRow(title: "위치 접근 권한", isOn: $allowLocationRecommend)
            ToggleRow(title: "알림 수신", isOn: $allowNotification)
        }
        .sectionContainer()
    }
}
