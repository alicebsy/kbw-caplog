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
            VStack(spacing: 16) {
                Form {
                    Section {
                        SecureField("현재 비밀번호", text: $currentPW)
                        SecureField("새 비밀번호", text: $newPW)
                        SecureField("새 비밀번호 확인", text: $confirmPW)
                    }
                }
                .scrollDisabled(true)

                // 가운데 정렬 + 파란색(토큰) 강조 버튼
                HStack {
                    CapsuleButton(
                        title: "비밀번호 변경",
                        action: validateAndSubmit,
                        tint: Color.myPageActionBlue,
                        fill: Color.myPageActionBlueBg,
                        fullWidth: true,
                        isEnabled: true,
                        // ✅ 2. 버튼 세로 높이 (기본 8 -> 12로)
                        verticalPadding: 12,
                        // ✅ 3. 버튼 폰트 크기 (기본 14 -> 16으로)
                        fontSize: 16
                    )
                }
                .padding(.horizontal, 20)

                Text("영문/숫자/특수문자 조합 8자 이상을 권장합니다.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            // ✅ 1. 상단 타이틀과 Form(입력칸) 사이 간격 추가
            .padding(.top, 16)
            .navigationTitle("비밀번호 변경")
            // ✅ 4. 타이틀 폰트 작게 (인라인 스타일)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .alert("안내", isPresented: $showAlert) {
                Button("확인") {
                    if alertMessage.contains("변경되었습니다") { dismiss() }
                }
            } message: { Text(alertMessage) }
        }
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
