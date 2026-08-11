import SwiftUI

struct UnderlineTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSecure {
                SecureField("", text: $text,
                            prompt: Text(placeholder).foregroundColor(Color.registerPlaceholder))
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .autocorrectionDisabled()
            } else {
                TextField("", text: $text,
                          prompt: Text(placeholder).foregroundColor(Color.registerPlaceholder))
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .autocorrectionDisabled()
            }
            // Divider()에 .background를 붙여도 색이 바뀌지 않습니다(자체 헤어라인을 그림).
            // 실제 화면에서 #ABACB0(2.17:1)로 찍혀서 명시적인 1pt 선으로 바꿉니다.
            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)
        }
    }
}
