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

            // ✅ 이름 + 저장 버튼
            HStack(spacing: 12) {
                Text("이름")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 90, alignment: .leading)
                
                TextField(
                    "", text: $name,
                    prompt: Text("강배우").foregroundColor(.gray)
                )
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                
                CapsuleButton(title: "저장", action: onSave)
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
