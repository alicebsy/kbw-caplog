import SwiftUI

/// 상세 화면은 라우트에서 전달한 id 기준으로 표시하도록 단순화
/// 실제 데이터 바인딩은 ViewModel/Service에서 교체 가능
struct HomeContentDetailView: View {
    let id: String

    // 임시 더미 데이터 (id로 fetching 전까지 안전하게 UI 표시용)
    private var title: String { "콘텐츠 #\(id)" }
    private var category: String { "카테고리 미정" }
    private var address: String { "주소 정보 없음" }
    private var tags: String { "#태그없음" }
    private var thumbnailName: String { "placeholder" } // Assets 내 플레이스홀더 이미지명

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 썸네일
                ZStack {
                    // 플레이스홀더 이미지 (없으면 시스템 심볼로 대체)
                    if UIImage(named: thumbnailName) != nil {
                        Image(thumbnailName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .padding(40)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // 텍스트 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2.bold())
                    Text(category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(address)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(tags)
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
        .background(Color.brandCardBG) // 없으면 Color(.systemBackground)로 교체
    }
}
