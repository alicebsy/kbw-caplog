import SwiftUI

/// 마이페이지 "스크린샷" 섹션: 갤러리에서 카드 가져오기, 새로고침
struct MyPageScreenshotSection: View {
    @Binding var isImporting: Bool
    var onImport: () -> Void
    var onRefresh: () -> Void
    @ObservedObject private var pipelineStatus = ScreenshotPipelineStatus.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "스크린샷")

            VStack(spacing: 0) {
                if pipelineStatus.lastUpdated != nil {
                    statusView
                    Divider()
                        .padding(.leading, 16)
                }

                Button {
                    onImport()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.pointTeal)
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
                                .foregroundStyle(Color.pointSlate.opacity(0.55))
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
                            .foregroundStyle(Color.pointTeal)
                        Text("전체 스크린샷 다시 인식")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        if !isImporting {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.pointSlate.opacity(0.55))
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

    private var statusView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 4) {
                    Text(pipelineStatus.lastMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    if let error = pipelineStatus.lastError,
                       pipelineStatus.phase != .running {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.brandTextSub)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }

            if pipelineStatus.isRunning && pipelineStatus.totalCount > 0 {
                ProgressView(value: pipelineStatus.progress)
                    .tint(Color.accentGreenTint)
                Text("\(pipelineStatus.currentCount)/\(pipelineStatus.totalCount) 처리 중")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.brandTextSub)
            }

            if pipelineStatus.phase == .warning || pipelineStatus.phase == .failure {
                Button("실패한 항목 다시 시도") {
                    onImport()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.accentGreenTint)
                .disabled(isImporting)
            }
        }
        .padding(16)
    }

    private var statusIcon: String {
        switch pipelineStatus.phase {
        case .idle: return "info.circle"
        case .running: return "wand.and.stars"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failure: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch pipelineStatus.phase {
        case .idle: return .secondary
        case .running, .success: return Color.accentGreenTint
        case .warning: return .orange
        case .failure: return .red
        }
    }
}
