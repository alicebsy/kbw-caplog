import SwiftUI

/// 마이페이지 "카드 관리" 섹션: 현황, 중복 제거, 로컬 초기화
struct MyPageCardCleanupSection: View {
    let cardCount: Int
    let duplicateCount: Int
    let screenshotCount: Int?
    @Binding var isRemovingDuplicates: Bool
    var onRemoveDuplicates: () -> Void
    var onResetAndReimport: (() -> Void)?

    private var duplicateByScreenshot: Int? {
        guard let sc = screenshotCount, sc > 0, cardCount > sc else { return nil }
        return cardCount - sc
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "카드 관리")

            VStack(alignment: .leading, spacing: 16) {
                // 현황
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("저장된 카드")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(cardCount)개")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    if let sc = screenshotCount, sc > 0 {
                        HStack {
                            Text("스크린샷")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(sc)개")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    if let dup = duplicateByScreenshot, dup > 0 {
                        Text("스크린샷보다 카드가 많아 중복일 수 있는 건 약 \(dup)건이에요.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if duplicateCount > 0 {
                        Text("같은 출처로 보이는 카드 \(duplicateCount)건을 정리할 수 있어요.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if screenshotCount != nil {
                        Text("중복 없음 · 스크린샷당 1개로 유지 중")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)

                // 중복 제거
                Button {
                    onRemoveDuplicates()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.myPageSectionGreen)
                        Text(duplicateCount > 0 ? "중복 제거하기" : "한 번 더 정리하기")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        if isRemovingDuplicates {
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
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                }
                .disabled(isRemovingDuplicates)

                // 로컬 초기화 (스크린샷만 남기기)
                if onResetAndReimport != nil {
                    Button {
                        onResetAndReimport?()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                            Text("로컬 카드 초기화 후 다시 가져오기")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .sectionContainer()
    }
}
