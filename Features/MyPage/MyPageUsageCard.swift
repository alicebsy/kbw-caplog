import SwiftUI
import Combine

struct MyPageUsageCard: View {
    let savedCount: Int
    let recommendedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 제목
            MyPageSectionHeader(title: "사용정보")

            // 카드 영역 - 1줄 레이아웃
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemGray6))
                .frame(height: 60)
                .padding(.horizontal, 2)
                .overlay(
                    HStack(spacing: 3) {
                        Text("📸")
                            .font(.system(size: 14))
                        Text("\(savedCount)")
                            .font(.system(size: 15, weight: .bold))
                        Text("건 정보 저장")
                            .font(.system(size: 14))
                        
                        Text("|")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        
                        Text("💡")
                            .font(.system(size: 14))
                        Text("\(recommendedCount)")
                            .font(.system(size: 15, weight: .bold))
                        Text("건 추천 받음")
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                )
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .sectionContainer()
    }
}
