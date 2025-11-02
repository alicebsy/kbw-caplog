import SwiftUI

struct SearchResultRow: View {
    let item: SearchItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: item.thumbnailURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().opacity(0.08)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let major = item.category, let sub = item.subCategory {
                    Text("\(major.rawValue) · \(sub.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}
