import SwiftUI

/// 약관·정책 문서와 회원 탈퇴를 모아둔 섹션.
///
/// 탈퇴를 여기 둔 이유: App Store 심사지침 5.1.1(v)는 계정 삭제 경로가 앱 안에서
/// 찾기 쉬운 곳에 있어야 한다고 봅니다. 설정 최하단이 관례적인 자리입니다.
struct MyPageLegalSection: View {
    var onOpenPrivacyPolicy: () -> Void
    var onOpenTerms: () -> Void
    var onDeleteAccount: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MyPageSectionHeader(title: "약관 및 계정")

            VStack(spacing: 0) {
                LegalDisclosureRow(
                    icon: "hand.raised.fill",
                    tint: .pointBlue,
                    title: "개인정보 처리방침",
                    action: onOpenPrivacyPolicy
                )
                MyPageRowDivider()
                LegalDisclosureRow(
                    icon: "doc.text.fill",
                    tint: .pointBlue,
                    title: "이용약관",
                    action: onOpenTerms
                )
                MyPageRowDivider()
                LegalDisclosureRow(
                    icon: "person.crop.circle.badge.xmark",
                    tint: .red,
                    title: "회원 탈퇴",
                    titleColor: .red,
                    action: onDeleteAccount
                )
            }
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .sectionContainer()
    }
}

private struct LegalDisclosureRow: View {
    var icon: String
    var tint: Color
    var title: String
    var titleColor: Color = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(tint)
                    .frame(width: 24, alignment: .center)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(titleColor)
                Spacer(minLength: 12)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.brandTextSub)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
