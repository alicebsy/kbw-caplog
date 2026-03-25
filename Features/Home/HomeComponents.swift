import SwiftUI

// MARK: - 공통 간격/높이
public enum HomeMetrics {
    /// 섹션 간(이전 카드 ↔ 다음 섹션 타이틀) 간격
    static let sectionSpacing: CGFloat = 18 // 중간 정도 여백
    /// 섹션 타이틀 ↔ 그 아래 카드 간격
    static let headerToCard: CGFloat = 8 // ✅ 8pt

    static let couponHeight: CGFloat = 180 // ✅ 130 → 180으로 증가
    static let rowHeight: CGFloat = 150
    static let carouselHeight: CGFloat = 180
}

// MARK: - 섹션 타이틀 (수평 패딩만, 위/아래 여백 없음)
struct HomeSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
        }
    }
}

// MARK: - 섹션: 타이틀 + 콘텐츠 (옵션 카드 래핑)
struct HomeSection<Content: View>: View {
    let title: String
    var wrapInCard: Bool = true
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HomeSectionHeader(title: title)
                .padding(.horizontal, 20)
            Spacer().frame(height: HomeMetrics.headerToCard)
            if wrapInCard {
                content
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
            } else {
                content
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - 상단 헤더 (심플한 진초록 타이포)
struct HomeHeader: View {
    let userName: String
    var onTapNotification: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(userName.isEmpty ? "Hello 👋" : "Hello, \(userName) 👋")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.homeGreenDark)
                Text("캡처한 로그를 한눈에 정리해요")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onTapNotification) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.homeGreenDark)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - Skeletons (로딩 자리표시자)
struct CouponSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.homeGreenLight.opacity(0.7))
            .frame(height: HomeMetrics.couponHeight)
            .padding(.horizontal, 20)
    }
}

struct RowSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.brandCardBG)
            .frame(height: HomeMetrics.rowHeight)
    }
}

struct CarouselSkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.brandCardBG)
            .padding(.horizontal, 20)
    }
}
