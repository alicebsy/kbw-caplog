import SwiftUI

// MARK: - Section Header
struct HomeSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.brandTextMain)
                .lineLimit(1)
            Spacer()
        }
        .padding(.top, 6)
    }
}

// MARK: - Recommended Row (좌 텍스트 / 우 썸네일)
struct HomeCardRow: View {
    let content: Content
    var onTap: () -> Void            // 카드(가운데) 탭 → 상세
    var onShare: () -> Void          // 공유 버튼
    var onTapMore: () -> Void        // … 버튼 → 상세정보 수정
    var onTapThumb: () -> Void       // 우측 썸네일 탭 → 이미지 전체보기

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // LEFT: 텍스트 블록
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.category)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                    Text(content.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(content.address.components(separatedBy: " ").first ?? "")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(content.address)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.brandTextSub)
                            .lineLimit(1)
                    }
                }

                if !content.tags.isEmpty {
                    Text(content.tags)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandTextSub)
                        .lineLimit(1)
                }

                // 하단 액션 (공유 / …)
                HStack(spacing: 14) {
                    Button(action: onShare) { Image(systemName: "square.and.arrow.up") }
                    Button(action: onTapMore) { Image(systemName: "ellipsis") }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.brandTextSub)
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            Spacer(minLength: 0)

            // RIGHT: 실제 썸네일 이미지
            Image(content.thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture { onTapThumb() }
        }
        .padding(18)
        .background(Color.brandCardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Recently Row (최근 본) — 4 콜백
struct RecentlyRow: View {
    let title: String
    let meta: String
    let thumb: String
    var onTapCenter: () -> Void
    var onTapShare: () -> Void
    var onTapMore: () -> Void
    var onTapThumb: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(thumb)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture { onTapThumb() }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(meta)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.brandTextSub)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture { onTapCenter() }

            Spacer()
            HStack(spacing: 14) {
                Button(action: onTapShare) { Image(systemName: "square.and.arrow.up") }
                Button(action: onTapMore)  { Image(systemName: "ellipsis") }
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.brandTextSub)
        }
        .padding(12)
        .background(Color.brandCardBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Minimal HomeHeader (stub for compile)
struct HomeHeader: View {
    let userName: String
    var onTapNotification: () -> Void
    var onTapProfile: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(userName)")
                    .font(.system(size: 22, weight: .bold))
                Text("Today’s Summary")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.brandTextSub)
            }
            Spacer()
            HStack(spacing: 12) {
                Button(action: onTapNotification) { Image(systemName: "bell") }
                Button(action: onTapProfile)     { Image(systemName: "person.circle") }
            }
            .font(.system(size: 20, weight: .semibold))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Minimal ExpiringCouponCard (stub for compile)
struct ExpiringCouponCard: View {
    let title: String
    let date: String
    let brand: String
    var onOpen: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.95))
                Text(date).font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text(brand).font(.system(size: 13)).foregroundStyle(.white.opacity(0.9))
                Button(action: onOpen) { Image(systemName: "chevron.right.circle.fill").font(.system(size: 24)) }
                    .tint(.white)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color.brandGreenCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
