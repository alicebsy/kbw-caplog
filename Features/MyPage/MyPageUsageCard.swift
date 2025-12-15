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
                .padding(.horizontal, 2)
                .overlay(
                    HStack(spacing: 4) {
                            Text("📸 ")
                            Text("\(savedCount)").bold()
                            Text("건의 정보 저장  |  💡 ")
                            Text("\(recommendedCount)").bold()
                            Text("건 추천 받음")
                        }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
                )
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .sectionContainer()
    }
}
