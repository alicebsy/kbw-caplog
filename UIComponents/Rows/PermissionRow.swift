import SwiftUI

/// 권한 하나의 현재 상태.
///
/// 예전에는 버튼 문구("허용됨" / "설정에서 허용")를 문자열로 비교해서 색을 정했습니다.
/// 문구를 고치면 색이 조용히 어긋나는 구조라 상태를 값으로 받습니다.
enum PermissionState {
    case notDetermined
    case granted
    case denied
}

/// 권한 안내 한 줄 (아이콘 + 설명 + 상태별 동작)
struct PermissionRow: View {
    let icon: String
    let title: String
    let desc: String
    let state: PermissionState
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                // 인증 화면 그라데이션 위 전경이라 authOnGradient를 씁니다.
                .foregroundColor(Color.authOnGradient)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.brandTextMain)
                Text(desc)
                    .font(.system(size: 12))
                    // 예전엔 .gray(#8E8E93)라 흰 배경에서도 3.23:1로 본문 기준에
                    // 못 미쳤습니다. 그라데이션 위에서는 더 떨어집니다.
                    .foregroundColor(Color.brandTextMain)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        // 흰 면을 깔면 그라데이션 위에 판때기가 얹힌 것처럼 보여서 테두리만 둡니다.
        // 0.75를 곱한 값이 그라데이션 위쪽에서 3.02:1입니다. 더 연하게 하면 3:1 밑으로 떨어집니다.
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.authOnGradient.opacity(0.75), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var trailing: some View {
        switch state {
        case .granted:
            // 이미 허용된 걸 다시 누를 일은 없습니다. 눌리는 것처럼 보이지 않게 둡니다.
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("허용됨")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color.authOnGradient)

        case .notDetermined:
            Button(action: action) {
                Text("허용")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.homeGreenDark)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

        case .denied:
            // iOS는 한 번 거부하면 다시 묻지 않습니다. 설정으로 보내는 수밖에 없습니다.
            Button(action: action) {
                Text("설정 열기")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.authOnGradient)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(Capsule().strokeBorder(Color.authOnGradient, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
    }
}
