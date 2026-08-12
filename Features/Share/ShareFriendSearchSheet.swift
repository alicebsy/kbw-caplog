import SwiftUI

struct ShareFriendSearchSheet: View {
    // ViewModel을 주입받음
    @ObservedObject var vm: ShareViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    /// 아이디를 아직 안 적었거나 요청을 보내는 중이면 버튼을 잠급니다.
    private var isDisabled: Bool {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 친구 ID 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("추가할 친구의 ID를 입력하세요")
                        .font(.subheadline)
                        // .secondary는 흰 면에서 3.26:1이라 본문 기준 AA에 못 미칩니다.
                        .foregroundColor(Color.brandTextSub)
                    
                    TextField("예: friend_id", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // 안내 문구
                Text("정확한 친구 ID를 입력하면 서버에 친구 추가 요청을 보낼게요.\n내 ID는 마이페이지에서 확인할 수 있어요.")
                    .font(.footnote)
                    .foregroundColor(Color.brandTextSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                // 추가 버튼
                Button {
                    Task { await addFriend() }
                } label: {
                    Text(isLoading ? "추가 중..." : "친구 추가")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isDisabled ? Color.brandTextSub : .white)
                        // 예전엔 비활성일 때도 흰 글씨에 옅은 회색 배경이라
                        // 버튼 이름이 거의 읽히지 않았습니다.
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isDisabled
                                    ? Color(uiColor: .tertiarySystemGroupedBackground)
                                    : Color.myPageSectionGreen)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(isDisabled)
            }
            .navigationTitle("친구 추가")
            .toolbar {
                // 닫기는 취소 계열입니다. 예전엔 확인 위치(.confirmationAction)에 있어서
                // 보이스오버가 결정 버튼처럼 읽었습니다.
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("친구 추가 실패", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    /// 서버에 친구 추가 요청
    private func addFriend() async {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        if await vm.addFriend(userId: trimmed) {
            dismiss()
        } else {
            errorMessage = vm.friendErrorMessage ?? "친구를 추가하지 못했습니다."
        }
    }
}
