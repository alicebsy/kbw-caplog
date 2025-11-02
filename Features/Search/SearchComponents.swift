import SwiftUI

// MARK: - Search 전용 상태 컴포넌트

struct SearchEmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("검색 결과가 없습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

struct SearchLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("검색 중입니다...")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

struct SearchErrorView: View {
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 28))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let retry {
                Button("다시 시도") { retry() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Search Components") {
    VStack(spacing: 20) {
        SearchEmptyStateView()
        SearchLoadingView()
        SearchErrorView(message: "네트워크 오류가 발생했습니다.")
    }
    .padding()
}
