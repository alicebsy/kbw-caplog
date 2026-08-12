import SwiftUI

struct CheckBoxView: View {
    @Binding var isChecked: Bool
    /// 문서를 열 때 호출합니다. nil이면 링크 줄을 그리지 않습니다.
    var onOpenDocument: ((LegalDocumentLink) -> Void)? = nil

    /// 체크박스가 동의를 받는 두 문서.
    enum LegalDocumentLink {
        case terms
        case privacy
    }

    var body: some View {
        // 체크 토글과 문서 링크는 서로 다른 동작이라 버튼을 따로 둡니다.
        // 예전처럼 한 버튼 안에 넣으면 링크를 눌러도 체크만 토글됩니다.
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isChecked.toggle()
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        // 회색 테두리는 인증 화면 그라데이션 위쪽에서 2.13:1까지 떨어집니다.
                        // 체크박스 테두리는 컨트롤 경계라 3:1이 필요합니다.
                        // 밝은 homeGreenDark도 그라데이션 위에서는 2.14:1이라 못 씁니다.
                        RoundedRectangle(cornerRadius: 6).stroke(Color.authOnGradient, lineWidth: 2)
                        if isChecked {
                            // checkMint(#8FD694)는 흰 체크 표시 대비가 1.72:1이라
                            // 체크 여부가 거의 보이지 않았습니다. 테두리와 같은 색으로 채웁니다.
                            RoundedRectangle(cornerRadius: 6).fill(Color.authOnGradient)
                            Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 12, weight: .bold))
                        }
                    }
                    .frame(width: 24, height: 24)

                    // 이 체크는 Register2에서 가입 필수 조건으로 쓰입니다
                    // ("약관에 동의해야 회원가입이 가능합니다"). 문구를 실제 동작에 맞췄습니다.
                    Text("[필수] 이용약관 및 개인정보처리방침에 동의합니다.")
                        .font(.system(size: 14)).foregroundColor(Color.brandTextMain).multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("이용약관 및 개인정보처리방침 동의")
            .accessibilityAddTraits(isChecked ? [.isSelected] : [])

            if let onOpenDocument {
                // 동의를 받으려면 동의 대상을 읽을 수 있어야 합니다.
                HStack(spacing: 14) {
                    documentLink("이용약관 보기") { onOpenDocument(.terms) }
                    documentLink("개인정보 처리방침 보기") { onOpenDocument(.privacy) }
                    Spacer(minLength: 0)
                }
                .padding(.leading, 32)
            }
        }
    }

    private func documentLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.authOnGradient)
                .underline()
        }
        .buttonStyle(.plain)
    }
}
