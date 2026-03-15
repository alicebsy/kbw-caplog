import SwiftUI
import Combine

struct MyPageUsageCard: View {
    let savedCount: Int
    let recommendedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MyPageSectionHeader(title: "사용정보")
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.myPageSectionGreen)
                    Text("\(savedCount)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("건 저장")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(Color(uiColor: .separator).opacity(0.4))
                    .frame(width: 1, height: 32)
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.myPageSectionGreen)
                    Text("\(recommendedCount)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("건 추천")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .sectionContainer()
    }
}
