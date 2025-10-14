import SwiftUI

struct MyPageAccountSection: View {
    @Binding var name: String
    let email: String
    var onChangePassword: () -> Void
    var onSave: () -> Void
    var isSaveEnabled: Bool = true   // ✅ 저장 버튼 활성/비활성 제어

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "가입정보")

            LabeledRow(label: "이름") {
                TextField("닉네임", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            LabeledRow(label: "이메일") {
                Text(email)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack {
                Text("PW 변경").font(.system(size: 15, weight: .semibold))
                Spacer()
                CapsuleButton(title: "비밀번호 변경", action: onChangePassword)
                CapsuleButton(title: "저장", action: onSave)
                    .opacity(isSaveEnabled ? 1 : 0.5)
                    .disabled(!isSaveEnabled)  // ✅ 비활성화
            }
        }
        .sectionContainer()
    }
}
