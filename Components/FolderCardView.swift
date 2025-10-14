import SwiftUI

struct FolderCardView: View {
    let item: FolderItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(item.category.rawValue) - \(item.subcategory)")
                .font(.system(size: 12))
                .foregroundColor(.brandTextSub)
            Text(item.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.brandTextMain)
            Text(item.description)
                .font(.system(size: 14))
                .foregroundColor(.brandTextSub)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.location)
                        .font(.system(size: 13))
                        .foregroundColor(.brandTextSub)
                    Text(item.date)
                        .font(.system(size: 12))
                        .foregroundColor(.brandTextSub)
                }
                Spacer()
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.brandCardBG)
        .cornerRadius(12)
    }
}
