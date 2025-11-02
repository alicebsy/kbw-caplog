//
//  ShareComponents.swift
//  KBW-CAPLOG
//
//  Created by Minha on 2025/11/03.
//

import SwiftUI

// MARK: - Share 전용 상태 컴포넌트

struct ShareEmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("공유할 항목이 없습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

struct ShareLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("공유 목록을 불러오는 중…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

struct ShareErrorView: View {
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

#Preview("Share Components") {
    VStack(spacing: 20) {
        ShareEmptyStateView()
        ShareLoadingView()
        ShareErrorView(message: "공유 데이터를 불러오지 못했습니다.")
    }
    .padding()
}
