import SwiftUI

struct HomeCardPopupView: View {
    let content: Content
    var onShare: () -> Void
    var onTapImage: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(content.name)
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                }
            }

            HStack(spacing: 12) {
                Image(content.thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture { onTapImage(content.screenshots.first ?? content.thumbnail) }

                VStack(alignment: .leading, spacing: 8) {
                    Text(content.category)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.brandTextSub)
                    Text(content.address)
                        .font(.system(size: 14))
                        .lineLimit(2)
                    Text(content.tags)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandTextSub)
                }
                Spacer()
            }

            Divider()

            if !content.screenshots.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(content.screenshots, id: \.self) { img in
                            Image(img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture { onTapImage(img) }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(Color.brandCardBG)
        .presentationDragIndicator(.visible)
    }
}
