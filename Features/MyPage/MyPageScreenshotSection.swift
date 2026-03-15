import SwiftUI

/// 마이페이지 "스크린샷" 섹션: 갤러리에서 카드 가져오기, 새로고침
struct MyPageScreenshotSection: View {
    @Binding var isImporting: Bool
    var onImport: () -> Void
    var onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "스크린샷")

            VStack(spacing: 0) {
                Button {
                    onImport()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.myPageSectionGreen)
                        Text("스크린샷에서 카드 가져오기")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        if isImporting {
                            ProgressView()
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .disabled(isImporting)

                Divider()
                    .padding(.leading, 44)

                Button {
                    onRefresh()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.myPageSectionGreen)
                        Text("스크린샷 새로고침 (전체 다시 인식)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        if !isImporting {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .disabled(isImporting)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .sectionContainer()
    }
}
