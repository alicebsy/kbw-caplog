import SwiftUI
import Combine

/// 채팅 목록 화면 (상단의 "채팅" 탭 컨텐츠)
@MainActor
struct ShareChatListView: View {
    @ObservedObject var vm: ShareViewModel   // 🔹 주입받기
    @State private var selectedThread: ChatThread?
    
    @State private var showFriendSelection = false

    var body: some View {
        ZStack {
            List {
                ForEach(vm.threads) { t in
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            
                            // 1:1 또는 그룹 아바타
                            ChatListAvatarView(vm: vm, thread: t)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // 첫 줄: 이름 + 시간
                                HStack(spacing: 0) {
                                    Text(t.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .lineLimit(1) // ✅ 제목 잘림 방지 (Ellipsis)
                                    Spacer()
                                    Text(vm.timeString(for: t.lastMessageAt))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // 둘째 줄: 메시지 + 안읽음표시(오른쪽 정렬)
                                HStack(spacing: 0) {
                                    if let cardTitle = t.lastMessageCardTitle {
                                        // ✅ (수정) 아이콘 변경
                                        Image(systemName: "doc.text.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .padding(.trailing, 4)
                                        Text(cardTitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    } else {
                                        Text(t.lastMessageText ?? "메시지가 없습니다")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // 99+ 안 읽음 배지 UI
                                    if t.unreadCount > 0 {
                                        Text(t.unreadCount > 99 ? "99+" : "\(t.unreadCount)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .frame(minWidth: 24)
                                            .frame(height: 24)
                                            .background(Capsule().fill(Color.unreadBadgeRed))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        
                        // 구분선
                        if t.id != vm.threads.last?.id {
                            Divider()
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedThread = t
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable { await vm.loadAll() }
            .navigationDestination(item: $selectedThread) { thread in
                ChatRoomView(vm: vm, thread: thread)
            }
            .sheet(isPresented: $showFriendSelection) {
                ShareFriendSelectionView(vm: vm) { selectedFriends in
                    Task {
                        await startGroupChat(with: selectedFriends)
                    }
                }
            }
            
            // 플로팅 새 채팅 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showFriendSelection = true
                    } label: {
                        Image(systemName: "plus.bubble.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    /// 그룹 채팅 시작
    private func startGroupChat(with friends: [Friend]) async {
        guard !friends.isEmpty else { return }
        
        if friends.count == 1 {
            let friend = friends[0]
            if let existingThread = vm.threads.first(where: { t in
                t.participantIds.count == 2 && t.participantIds.contains(friend.id)
            }) {
                selectedThread = existingThread
            } else {
                let newThread = ChatThread(
                    id: "new_\(friend.id)_\(UUID().uuidString)",
                    title: friend.name,
                    participantIds: ["me", friend.id],
                    lastMessageText: nil,
                    lastMessageAt: Date(),
                    unreadCount: 0
                )
                await vm.addNewThread(newThread)
                selectedThread = newThread
            }
        } else {
            let participantIds = ["me"] + friends.map { $0.id }
            let title = friends
                .map { $0.name }
                .sorted()
                .joined(separator: ", ")
            
            let newThread = ChatThread(
                id: "new_group_\(UUID().uuidString)",
                title: title, // ❗️ 이 제목은 loadAll()에서 잘림 처리될 수 있습니다.
                participantIds: participantIds,
                lastMessageText: nil,
                lastMessageAt: Date(),
                unreadCount: 0
            )
            
            await vm.addNewThread(newThread)
            selectedThread = newThread
        }
    }
}

// MARK: - 채팅 목록 아바타 뷰

/// 채팅 목록의 썸네일을 담당 (1:1 프로필, 그룹 인원 수)
private struct ChatListAvatarView: View {
    let vm: ShareViewModel
    let thread: ChatThread

    var body: some View {
        if thread.participantIds.count > 2 {
            // --- 3인 이상 그룹 채팅: 인원 수 ---
            ZStack {
                Circle().fill(Color.gray.opacity(0.2))
                Text("\(thread.participantIds.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, height: 40)
        } else {
            // --- 1:1 채팅: 상대방 프로필 ---
            let otherParticipantID = thread.participantIds.first(where: { $0 != "me" })
            let friend = vm.friends.first(where: { $0.id == otherParticipantID })
            
            ChatListProfileImage(friend: friend)
        }
    }
}

/// 1:1 채팅 프로필 이미지 (Asset 이름 사용)
private struct ChatListProfileImage: View {
    let friend: Friend?
    
    var body: some View {
        // ✅ (수정) FriendManager.mockFriends에서 아바타 "이름"을 직접 찾음
        let shareFriend = FriendManager.mockFriends.first(where: { $0.id == friend?.id })
        
        Group {
            if let avatarName = shareFriend?.avatar, avatarName != "avatar_default" {
                Image(avatarName)
                    .resizable()
                    .scaledToFill()
            } else {
                defaultAvatar
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            )
    }
}
