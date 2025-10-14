import SwiftUI
import Combine

struct HomeCardHorizontal: View {
    let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(content.thumbnail)
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(content.category)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.brandTextSub)
                Text(content.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(content.address)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.brandTextSub)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(Color.brandCardBG)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
    }
}
