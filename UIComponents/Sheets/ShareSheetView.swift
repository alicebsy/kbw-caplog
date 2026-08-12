import SwiftUI

/// 🔗 홈/폴더 어디서든 재사용 가능한 공유 시트
struct ShareSheetView<T: Identifiable>: View {
    let target: T // 공유할 카드
    
    var onSend: (_ friendIDs: Set<String>, _ threadIDs: Set<String>, _ message: String) -> Void

    @Environment(\.dismiss) private var dismiss
    
    // ✅ (수정) 싱글톤 ViewModel 사용
    @StateObject private var vm = ShareViewModel.shared
    
    // 탭 상태
    @State private var innerTab: ShareInnerTab = .friends
    
    // 선택 상태
    @State private var message = ""
    @State private var selectedFriendIDs: Set<String> = []
    @State private var selectedThreadIDs: Set<String> = []
    
    private var hasSelection: Bool {
        !selectedFriendIDs.isEmpty || !selectedThreadIDs.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // 상단바
            HStack {
                Text("공유")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .accessibilityLabel("닫기")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandTextSub)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // 탭 버튼
            HStack(spacing: 12) {
                Button { innerTab = .friends } label: {
                    Label("친구", systemImage: "person.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(innerTab == .friends ? Color.brandTextMain : Color.brandTextSub)
                        .padding(.vertical, 8).padding(.horizontal, 10)
                        .background(Capsule().fill(innerTab == .friends ? Color.secondary.opacity(0.15) : .clear))
                }
                Button { innerTab = .chats } label: {
                    Label("채팅", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(innerTab == .chats ? Color.brandTextMain : Color.brandTextSub)
                        .padding(.vertical, 8).padding(.horizontal, 10)
                        .background(Capsule().fill(innerTab == .chats ? Color.secondary.opacity(0.15) : .clear))
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.bottom, 6)
            
            Divider()

            // 친구 목록 / 채팅 목록
            Group {
                if vm.isLoading && vm.friends.isEmpty && vm.threads.isEmpty {
                    ProgressView()
                } else {
                    switch innerTab {
                    case .friends:
                        List(vm.friends) { friend in
                            SelectableFriendRow(
                                friend: friend,
                                isSelected: selectedFriendIDs.contains(friend.id)
                            )
                            .onTapGesture {
                                if selectedFriendIDs.contains(friend.id) {
                                    selectedFriendIDs.remove(friend.id)
                                } else {
                                    selectedFriendIDs.insert(friend.id)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        
                    case .chats:
                        List(vm.threads) { thread in
                            ChatThreadRow(
                                vm: vm,
                                thread: thread,
                                isSelected: selectedThreadIDs.contains(thread.id)
                            )
                            .onTapGesture {
                                if selectedThreadIDs.contains(thread.id) {
                                    selectedThreadIDs.remove(thread.id)
                                } else {
                                    selectedThreadIDs.insert(thread.id)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider().padding(.top, 8)

            // 메시지 입력
            HStack(spacing: 10) {
                TextField("메시지를 입력하세요", text: $message)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brandLine))
                Button {
                    onSend(selectedFriendIDs, selectedThreadIDs, message)
                    dismiss()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .accessibilityLabel("보내기")
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 48)
                        .background(Color.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!hasSelection)
                .opacity(hasSelection ? 1 : 0.5)
            }
            .padding(16)
        }
        .background(Color.brandCardBG)
        .task {
            // 시트가 나타날 때 *공유* VM의 데이터 로드
            await vm.loadAll()
        }
    }
}
