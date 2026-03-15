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
        VStack(alignment: .leading, spacing: 0) {
            MyPageSectionHeader(title: "가입정보")

            VStack(spacing: 0) {
                // 이름 행
                HStack(spacing: 14) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.myPageSectionGreen)
                        .frame(width: 24, alignment: .center)
                    Text("이름")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 72, alignment: .leading)
                    TextField("", text: $name, prompt: Text("이름 입력").foregroundColor(.secondary))
                        .font(.system(size: 15))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isNameFocused)
                        .foregroundColor(nameColor)
                        .onAppear { originalName = name }
                    CapsuleButton(
                        title: "저장",
                        action: onSave,
                        tint: .white,
                        fill: .clear,
                        fullWidth: false,
                        isEnabled: isSaveEnabled,
                        verticalPadding: 6,
                        fontSize: 13,
                        isPrimary: true
                    )
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)

                MyPageRowDivider()

                // 아이디 행
                HStack(spacing: 14) {
                    Image(systemName: "at")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.myPageSectionGreen)
                        .frame(width: 24, alignment: .center)
                    Text("아이디")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 72, alignment: .leading)
                    Text(userId)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 8)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)

                MyPageRowDivider()

                // 이메일 행
                HStack(spacing: 14) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.myPageSectionGreen)
                        .frame(width: 24, alignment: .center)
                    Text("이메일")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 72, alignment: .leading)
                    Text(email)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 8)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .sectionContainer()
    }

    private var nameColor: Color {
        if isNameFocused { return .primary }
        if name != originalName { return .primary }
        return .secondary
    }
}
