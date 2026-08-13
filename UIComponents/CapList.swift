import SwiftUI

// MARK: - 공용 그룹 리스트 (iOS 설정 앱 문법)
/// 테두리·그림자 없이 톤 차이로만 묶고, 구분선은 글자 시작점까지 들여씁니다.
/// 색은 새로 만들지 않고 이미 있는 토큰(`brandTextMain`/`brandTextSub`/`homeGreenDark`)과
/// 시스템 그룹 배경을 씁니다. 초록을 하나 더 늘리면 화면이 다시 정신없어집니다.

// MARK: 섹션 머리글
struct CapSectionHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.brandTextSub)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }
}

// MARK: 구분선
struct CapSeparator: View {
    /// 왼쪽 들여쓰기 — 앞에 타일이 없는 행은 16, 타일이 있는 행은 62.
    var inset: CGFloat = 16

    var body: some View {
        Rectangle()
            .fill(Color(uiColor: .separator))
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

// MARK: 그룹 (면 + 12pt 라운드)
struct CapGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
    }
}

// MARK: 행
struct CapRow: View {
    let title: String
    var subtitle: String? = nil
    /// 우측 숫자 — 자릿수가 흔들리지 않게 고정폭 숫자로 그립니다.
    var value: String? = nil
    var systemImage: String? = nil
    var showsChevron: Bool = true
    /// 개수가 0인 항목은 글자를 흐리게 내립니다.
    var isDimmed: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.brandTextSub)
                    .frame(width: 34, height: 34)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundStyle(isDimmed ? Color.brandTextSub : Color.brandTextMain)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                }
            }

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(.system(size: 16).monospacedDigit())
                    .foregroundStyle(Color.brandTextSub)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brandTextSub.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

// MARK: 대분류 칩
struct CapChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            // homeGreenDark(#0E7A50) 위 흰 글자는 5.36:1로 AA 통과.
            .foregroundStyle(isSelected ? Color.white : Color.brandTextMain)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? Color.homeGreenDark
                : Color(uiColor: .secondarySystemGroupedBackground)
            )
            .clipShape(Capsule())
    }
}
