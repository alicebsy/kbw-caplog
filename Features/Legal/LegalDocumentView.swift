import SwiftUI

/// 개인정보 처리방침·이용약관을 읽는 화면.
///
/// 외부 브라우저로 내보내지 않고 앱 안에서 보여줍니다. 링크가 죽으면 심사에서
/// 문제가 되고, 가입 전 사용자는 인터넷 연결이 불안정할 수도 있기 때문입니다.
struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.brandTextMain)
                    Text(document.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.brandTextSub)
                }

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.heading)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.brandTextMain)
                        Text(section.body)
                            .font(.system(size: 14))
                            .foregroundColor(Color.brandTextMain)
                            // 문단이 길어 줄바꿈이 잘리지 않게 고정 크기를 풉니다.
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 시트로 띄울 때 쓰는 감싸개. 닫기 버튼이 필요해서 따로 둡니다.
struct LegalDocumentSheet: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LegalDocumentView(document: document)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("닫기") { dismiss() }
                            .foregroundColor(Color.brandTextMain)
                    }
                }
        }
    }
}
