import SwiftUI

/// 회원 탈퇴 시트.
///
/// 되돌릴 수 없는 동작이라 "탈퇴"를 직접 입력해야 버튼이 열립니다.
/// 실수로 누르는 걸 막으면서도, App Store 심사지침 5.1.1(v)가 요구하는
/// "앱 안에서 계정을 지울 수 있는 경로"는 두 번의 탭으로 닿습니다.
struct MyPageAccountDeletionView: View {
    @ObservedObject var vm: MyPageViewModel
    @Environment(\.dismiss) private var dismiss

    /// 사용자가 그대로 입력해야 하는 확인 문구.
    private static let confirmationPhrase = "탈퇴"

    @State private var typedPhrase = ""
    /// 탈퇴 실패 문구. 뷰모델의 errorMessage를 쓰면 마이페이지 알림과 겹쳐 뜹니다.
    @State private var failureMessage: String?

    private var canDelete: Bool {
        typedPhrase.trimmingCharacters(in: .whitespaces) == Self.confirmationPhrase && !vm.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    deletionList
                    keepInMind
                    confirmationField
                    deleteButton
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("회원 탈퇴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(Color.brandTextMain)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            Text("탈퇴하면 되돌릴 수 없어요")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.brandTextMain)
            Text("계정과 아래 데이터가 서버에서 즉시 삭제됩니다. 같은 아이디로 다시 가입해도 복구되지 않습니다.")
                .font(.system(size: 14))
                .foregroundColor(Color.brandTextSub)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var deletionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            deletionRow(icon: "rectangle.stack.fill", text: "저장한 카드와 스크린샷 기록 전부")
            MyPageRowDivider()
            deletionRow(icon: "person.2.fill", text: "친구 관계 (상대 친구 목록에서도 사라집니다)")
            MyPageRowDivider()
            deletionRow(icon: "bubble.left.and.bubble.right.fill", text: "내가 보낸 채팅 메시지와 카드")
            MyPageRowDivider()
            deletionRow(icon: "person.crop.circle.fill", text: "이름·이메일·생년월일 등 프로필 정보")
        }
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func deletionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.red)
                .frame(width: 22, alignment: .center)
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color.brandTextMain)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    private var keepInMind: some View {
        // 다른 사람에게 남는 것도 미리 알려줍니다. 탈퇴 후에 "왜 남아 있냐"는 오해를 막습니다.
        Text("참고: 이미 친구에게 보낸 카드 중 상대가 자기 카드로 저장한 것은 상대의 데이터라 지워지지 않습니다.")
            .font(.system(size: 13))
            .foregroundColor(Color.brandTextSub)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var confirmationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("계속하려면 \"\(Self.confirmationPhrase)\"를 입력해 주세요")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.brandTextMain)
            TextField(
                "",
                text: $typedPhrase,
                prompt: Text(Self.confirmationPhrase).foregroundColor(Color.brandTextSub)
            )
            .font(.system(size: 16))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(10)
            .accessibilityLabel("확인 문구 입력")
        }
    }

    private var deleteButton: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    // 성공하면 logoutCompleted가 발송돼 앱이 랜딩 화면으로 돌아갑니다.
                    // 실패했을 때만 시트를 남겨 오류 문구를 보여주고 다시 시도하게 합니다.
                    failureMessage = await vm.deleteAccount()
                    if failureMessage == nil { dismiss() }
                }
            } label: {
                HStack(spacing: 8) {
                    if vm.isLoading { ProgressView().tint(.white) }
                    Text(vm.isLoading ? "탈퇴 처리 중…" : "회원 탈퇴")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundColor(.white)
                .background(canDelete ? Color.red : Color.red.opacity(0.35))
                .cornerRadius(12)
            }
            .disabled(!canDelete)

            if let message = failureMessage {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
