import SwiftUI

struct ShareFriendSearchSheet: View {
    // ViewModel을 주입받음
    @ObservedObject var vm: ShareViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 친구 ID 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("추가할 친구의 ID를 입력하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("예: friend_id", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // 안내 문구
                Text("정확한 친구 ID를 입력하면 서버에 친구 추가 요청을 보낼게요.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // 추가 버튼
                Button {
                    Task { await addFriend() }
                } label: {
                    Text(isLoading ? "추가 중..." : "친구 추가")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                                    ? Color.gray.opacity(0.5)
                                    : Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .navigationTitle("친구 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
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
        
        do {
            let api = FriendAPI()
            _ = try await api.add(userId: trimmed)
            
            // 서버에서 성공적으로 추가되면 친구 목록을 다시 로드
            await vm.reloadFriends()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
