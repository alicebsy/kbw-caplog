import SwiftUI

// MARK: - 공통 간격/높이
public enum HomeMetrics {
    /// 섹션 간(이전 카드 ↔ 다음 섹션 타이틀) 간격
    static let sectionSpacing: CGFloat = 24 // ✅ 24pt
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
                .foregroundStyle(Color.black)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - “타이틀 ↔ 카드 간격”을 항상 동일하게 만드는 래퍼
struct HomeSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            HomeSectionHeader(title: title)
            Spacer().frame(height: HomeMetrics.headerToCard)   // 8pt 적용
            content
        }
    }
}

// MARK: - 상단 헤더
struct HomeHeader: View {
    let userName: String
    var onTapNotification: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Hello, \(userName) 👋")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.black)
            Spacer()
            // ✅ 수정: 알림(종) 아이콘 원래 위치로 복원
            Button(action: onTapNotification) {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .padding(.trailing, 10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12) // ✅ HomeView 상단 여백 대신 여기서 처리
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
