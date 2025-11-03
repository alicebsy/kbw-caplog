import SwiftUI

// MARK: - 설정 섹션
struct MyPageSettingsSection: View {
    @Binding var allowLocationRecommend: Bool
    @Binding var allowNotification: Bool
    var onLocationToggle: (Bool) -> Void
    var onNotificationToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "설정")

            ToggleRowWithAction(
                title: "위치 접근 권한",
                isOn: $allowLocationRecommend,
                action: onLocationToggle
            )
            
            ToggleRowWithAction(
                title: "알림 수신",
                isOn: $allowNotification,
                action: onNotificationToggle
            )
        }
        .sectionContainer()
    }
}

// MARK: - 액션이 있는 토글 행
private struct ToggleRowWithAction: View {
    var title: String
    @Binding var isOn: Bool
    var action: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SlimToggleStyle())
                .onChange(of: isOn) { _, newValue in
                    action(newValue)
                }
        }
    }
}
