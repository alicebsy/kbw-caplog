import SwiftUI

struct MyPageUsageCard: View {
    let savedCount: Int
    let recommendedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "사용정보")
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemGray6))
                .overlay(
                    HStack {
                        Text("📸 \(savedCount)건의 정보 저장  |  💡 \(recommendedCount)건 추천 받음")
                            .font(.system(size: 15))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                )
                .frame(height: 44)
        }
        .sectionContainer()
    }
}
