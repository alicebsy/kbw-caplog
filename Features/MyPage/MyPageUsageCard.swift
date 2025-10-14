import SwiftUI
import Combine

struct MyPageUsageCard: View {
    let savedCount: Int
    let recommendedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 제목
            MyPageSectionHeader(title: "사용정보")

            // 카드 영역
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemGray6))
                .frame(height: 60)
                .overlay(
                    VStack(spacing: 6) {
                        Text("📸 \(savedCount)건의 정보 저장  |  💡 \(recommendedCount)건 추천 받음")
                            .font(.system(size: 15))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
                )
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .sectionContainer()
    }
}
