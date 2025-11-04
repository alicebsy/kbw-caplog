import SwiftUI

struct MyPageAccountSection: View {
    @Binding var name: String
    let email: String
    var onChangePassword: () -> Void
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

                CapsuleButton(
                    title: "저장",
                    action: onSave,
                    tint: Color.myPageActionBlue,
                    fill: Color.myPageActionBlueBg,
                    fullWidth: false,
                    isEnabled: isSaveEnabled
                )
            }

            LabeledRow(label: "이메일") {
                Text(email)
                    .foregroundColor(.black)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack {
                Text("PW 변경").font(.system(size: 15, weight: .semibold))
                Spacer()
                CapsuleButton(
                    title: "비밀번호 변경",
                    action: onChangePassword,
                    tint: .primary,
                    fill: .white
                )
            }
        }
        .sectionContainer()
    }

    private var nameColor: Color {
        if isNameFocused { return .black }
        if name != originalName { return .black }
        return .gray
    }
}
