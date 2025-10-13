import SwiftUI

struct MyPageAccountSection: View {
    @Binding var name: String
    let email: String
    var onChangePassword: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "가입정보")

            LabeledRow(label: "이름") { TextField("닉네임", text: $name).textFieldStyle(.roundedBorder) }
            LabeledRow(label: "이메일") { Text(email).foregroundStyle(.secondary) }

            HStack {
                Text("PW 변경").font(.system(size: 15, weight: .semibold))
                Spacer()
                CapsuleButton(title: "비밀번호 변경", action: onChangePassword)
                CapsuleButton(title: "저장", action: onSave)
            }
        }
        .sectionContainer()
    }
}
