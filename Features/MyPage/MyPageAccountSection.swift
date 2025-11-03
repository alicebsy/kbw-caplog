import SwiftUI

struct MyPageAccountSection: View {
    @Binding var name: String
    let email: String
    var onChangePassword: () -> Void
    var onSave: () -> Void
    var isSaveEnabled: Bool = true
    
    // ✅ 이름 입력 포커스 상태 추적
    @FocusState private var isNameFocused: Bool
    @State private var originalName: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MyPageSectionHeader(title: "가입정보")

            // ✅ 이름 + 저장 버튼
            HStack(spacing: 12) {
                Text("이름")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 90, alignment: .leading)
                
                TextField(
                    "",
                    text: $name,
                    prompt: Text("강배우").foregroundColor(.gray)
                )
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isNameFocused)
                // ✅ 텍스트 색상 조건 변경
                .foregroundColor(nameColor)
                .onAppear {
                    originalName = name
                }
                .onChange(of: isNameFocused) { focused in
                    // 포커스 잃었을 때 업데이트 반영
                    if !focused {
                        originalName = originalName // 유지
                    }
                }

                CapsuleButton(title: "저장", action: onSave)
            }

            // ✅ 이메일: 항상 검은색
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
                CapsuleButton(title: "비밀번호 변경", action: onChangePassword)
            }
        }
        .sectionContainer()
    }

    // ✅ 이름 색상 로직
    private var nameColor: Color {
        if isNameFocused { return .black } // 입력 중이면 검정
        if name != originalName { return .black } // 수정 후 변경됨
        return .gray // 기본 상태
    }
}
