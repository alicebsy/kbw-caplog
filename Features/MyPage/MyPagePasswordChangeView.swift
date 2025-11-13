import SwiftUI

struct MyPagePasswordChangeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPW = ""
    @State private var newPW = ""
    @State private var confirmPW = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 여백
                Spacer()
                    .frame(height: 40)
                
                // 제목
                Text("비밀번호 변경")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                    .frame(height: 32)
                
                // 입력 필드들
                VStack(spacing: 16) {
                    // 현재 비밀번호
                    SecureField("현재 비밀번호", text: $currentPW)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    // 새 비밀번호
                    SecureField("새 비밀번호", text: $newPW)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    // 새 비밀번호 확인
                    SecureField("새 비밀번호 확인", text: $confirmPW)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 24)
                
                // 변경 버튼
                Button(action: validateAndSubmit) {
                    Text("비밀번호 변경")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(allFieldsFilled ? Color.myPageActionBlue : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            allFieldsFilled
                                ? Color.myPageActionBlueBg
                                : Color(.systemGray5)
                        )
                        .cornerRadius(12)
                }
                .disabled(!allFieldsFilled)
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 20)
                
                // 안내 문구
                Text("영문/숫자/특수문자 조합 8자 이상을 권장합니다.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .alert("안내", isPresented: $showAlert) {
                Button("확인") {
                    if alertMessage.contains("변경되었습니다") { dismiss() }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.visible)
    }
    
    private var allFieldsFilled: Bool {
        !currentPW.isEmpty && !newPW.isEmpty && !confirmPW.isEmpty
    }

    private func validateAndSubmit() {
        guard !currentPW.isEmpty, !newPW.isEmpty, !confirmPW.isEmpty else {
            alertMessage = "모든 항목을 입력해주세요."
            showAlert = true
            return
        }
        guard newPW == confirmPW else {
            alertMessage = "새 비밀번호와 확인이 일치하지 않습니다."
            showAlert = true
            return
        }
        // TODO: 실제 API 연동
        alertMessage = "비밀번호가 변경되었습니다."
        showAlert = true
    }
}

#Preview {
    MyPagePasswordChangeView()
}
