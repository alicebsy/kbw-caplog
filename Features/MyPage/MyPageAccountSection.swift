import SwiftUI

struct MyPageAccountSection: View {
    @Binding var name: String
    let email: String
    var onChangePassword: () -> Void
    var onSave: () -> Void
    var isSaveEnabled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "가입정보")

            // ✅ 닉네임 입력란에 placeholder 추가
            LabeledRow(label: "이름") {
                TextField(
                    "", text: $name,
                    prompt: Text("강배우").foregroundColor(.gray)
                )
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
            }
        }
        .sectionContainer()
    }
}
