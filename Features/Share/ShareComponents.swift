import SwiftUI

struct ShareFriend: Identifiable, Hashable {
    let id: String
    var name: String
    var avatar: String
}

// 친구 한 줄(이름만) 공용 컴포넌트
struct FriendRow: View {
    let name: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            Text(name)
                .font(.headline)
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

// ✅ 체크박스가 있는 친구 한 줄
struct SelectableFriendRow: View {
    let friend: Friend
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지 (목업)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            // 이름
            Text(friend.name)
                .font(.headline)
            
            Spacer()
            
            // 체크박스
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - ✅ (추가) 선택 가능한 채팅방 행

struct ChatThreadRow: View {
    let vm: ShareViewModel
    let thread: ChatThread
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 1:1 또는 그룹 아바타
            ChatListAvatarView(vm: vm, thread: thread)
            
            // 채팅방 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(thread.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                // 마지막 메시지 (카드 또는 텍스트)
                HStack(spacing: 4) {
                    if let cardTitle = thread.lastMessageCardTitle {
                        Image(systemName: "doc.text.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(cardTitle)
                    } else {
                        Text(thread.lastMessageText ?? "...")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            
            Spacer()
            
            // 체크박스
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// (ShareChatListView에 있던 헬퍼 뷰를 여기로 이동)
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
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            )
    }
}
