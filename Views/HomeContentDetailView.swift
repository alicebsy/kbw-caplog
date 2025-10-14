import SwiftUI

struct HomeContentDetailView: View {
    let content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(content.thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text(content.name)
                        .font(.title2.bold())
                    Text(content.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(content.address)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(content.tags)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
            .padding(.top, 20)
        }
        .navigationTitle("상세 정보")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.brandCardBG)
    }
}

