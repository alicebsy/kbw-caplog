import SwiftUI

// MARK: - Section Header (통일된 스타일)
struct HomeSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.black)  // ✅ brandTextMain → black
                .lineLimit(1)
            Spacer()
        }
        .padding(.top, 6)
    }
}

// MARK: - 기존 HomeCardRow, RecentlyRow 삭제됨
// → UnifiedCardView 사용 (HomeView.swift에서 직접 호출)

// MARK: - HomeHeader
struct HomeHeader: View {
    let userName: String
    var onTapNotification: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {  // ✅ spacing 16 → 12
            // ✅ "Hello, 강배우 😊" 이모지 추가
            Text("Hello, \(userName) 😊")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            // ✅ 알림 아이콘: 테두리만, 파란색
            Button(action: onTapNotification) {
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.blue)  // ✅ 파란색
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)  // ✅ 상단 여백 유지
    }
}

// MARK: - ExpiringCouponCard (개선됨)
struct ExpiringCouponCard: View {
    let title: String
    let date: String
    let brand: String
    var onOpen: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                // ✅ "Starbucks | 무료 음료 쿠폰" 형식 + 굵게
                Text("\(brand) | \(title)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(date)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Button(action: onOpen) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.brandGreenCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
