import SwiftUI

struct MyPageSettingsSection: View {
    @Binding var allowLocationRecommend: Bool
    @Binding var allowNotification: Bool
    var onLocationToggle: (Bool) -> Void
    var onNotificationToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MyPageSectionHeader(title: "설정")

            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "location.fill",
                    title: "위치 접근 권한",
                    subtitle: "위치 기반 추천에 사용돼요",
                    isOn: $allowLocationRecommend,
                    action: onLocationToggle
                )
                MyPageRowDivider()
                SettingsToggleRow(
                    icon: "bell.fill",
                    title: "알림 수신",
                    subtitle: "마감 임박 등 알림을 받아요",
                    isOn: $allowNotification,
                    action: onNotificationToggle
                )
            }
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .sectionContainer()
    }
}

private struct SettingsToggleRow: View {
    var icon: String
    var title: String
    var subtitle: String?
    @Binding var isOn: Bool
    var action: (Bool) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color.myPageSectionGreen)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SlimToggleStyle())
                .onChange(of: isOn) { _, newValue in
                    action(newValue)
                }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
