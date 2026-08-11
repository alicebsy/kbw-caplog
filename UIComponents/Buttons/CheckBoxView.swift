import SwiftUI

struct CheckBoxView: View {
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    // 회색 테두리는 인증 화면 그라데이션 위쪽에서 2.13:1까지 떨어집니다.
                    // 체크박스 테두리는 컨트롤 경계라 3:1이 필요합니다.
                    RoundedRectangle(cornerRadius: 6).stroke(Color.homeGreenDark, lineWidth: 2)
                    if isChecked {
                        // checkMint(#8FD694)는 흰 체크 표시 대비가 1.72:1이라
                        // 체크 여부가 거의 보이지 않았습니다. 앱 주 색상으로 통일합니다.
                        RoundedRectangle(cornerRadius: 6).fill(Color.homeGreenDark)
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
    }
}
