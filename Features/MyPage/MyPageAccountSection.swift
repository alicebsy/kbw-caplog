import SwiftUI

struct MyPageAccountSection: View {
    @Binding var name: String
    let userId: String
    let email: String
    var onSave: () -> Void
    var isSaveEnabled: Bool = true

    @FocusState private var isNameFocused: Bool
    @State private var originalName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "가입정보")

            HStack(spacing: 12) {
                Text("이름")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 90, alignment: .leading)

                TextField("", text: $name, prompt: Text("강배우").foregroundColor(.gray))
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isNameFocused)
                    .foregroundColor(nameColor)
                    .onAppear { originalName = name }

                Spacer(minLength: 8)

                CapsuleButton(
                    title: "저장",
                    action: onSave,
                    tint: .primary,
                    fill: .white,
                    fullWidth: false,
                    isEnabled: isSaveEnabled
                )
            }

            LabeledRow(label: "아이디") {
                Text(userId)
                    .foregroundColor(.black)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            LabeledRow(label: "이메일") {
                Text(email)
                    .foregroundColor(.black)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // ✅ 기존의 "PW 변경" 행은 완전히 제거됨
        }
        .sectionContainer()
    }

    private var nameColor: Color {
        if isNameFocused { return .black }
        if name != originalName { return .black }
        return .gray
    }
}
