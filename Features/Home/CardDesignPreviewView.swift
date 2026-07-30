import SwiftUI

#if DEBUG
/// 실제 사용자 데이터와 서버 DB를 변경하지 않는 카드 UI 확인용 화면입니다.
struct CardDesignPreviewView: View {
    private let previewCard = Card(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
        title: "목화반점 강남점",
        summary: "강남역 근처에서 짜장면과 짬뽕을 맛볼 수 있는 중식당이에요.",
        category: .info,
        subcategory: "맛집",
        tags: ["목화반점", "강남 맛집", "짜장면", "짬뽕"],
        fields: [
            "장소명": "목화반점 강남점",
            "주소": "서울 강남구 테헤란로",
            "메뉴": "짜장면, 짬뽕"
        ],
        thumbnailURL: "목화반점",
        screenshotURLs: ["목화반점"]
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("카드 디자인 미리보기")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.brandTextMain)
                        Text("실제 데이터에는 저장되지 않는 확인용 카드입니다.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.homeGraySub)
                    }

                    UnifiedCardView(
                        card: previewCard,
                        style: .row,
                        onTap: {},
                        onMore: {},
                        onTapImage: {}
                    )
                    .frame(minHeight: HomeMetrics.rowHeight)

                    VStack(alignment: .leading, spacing: 10) {
                        Label("카테고리는 아이콘 배지로 구분", systemImage: "tag.fill")
                        Label("제목과 요약의 글자 위계 강화", systemImage: "textformat.size")
                        Label("핵심 키워드 2개와 나머지 개수 표시", systemImage: "number")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.homeGreenDark)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.homeGreenDark.opacity(0.07))
                    )
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("CapLog")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
