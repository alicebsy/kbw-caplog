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
            // ✅ (수정) 공용 뷰 사용
            ProfileAvatarView(
                profileImage: friend.profileImage,
                avatarURL: friend.avatarURL?.absoluteString
            )
            
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
struct ChatListAvatarView: View {
    let vm: ShareViewModel
    let thread: ChatThread

    var body: some View {
        if thread.participantIds.count > 2 {
            // --- 3인 이상 그룹 채팅: 인원 수 ---
            ZStack {
                Circle().fill(Color.brandAccent.opacity(0.15))
                Text("\(thread.participantIds.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brandAccent)
            }
            .frame(width: 40, height: 40)
        } else {
            // --- 1:1 채팅: 상대방 프로필 ---
            let otherParticipantID = thread.participantIds.first(where: { $0 != "me" })
            let friend = vm.friends.first(where: { $0.id == otherParticipantID })
            
            // ✅ (수정) 공용 뷰 사용
            ProfileAvatarView(
                profileImage: friend?.profileImage,
                avatarURL: friend?.avatarURL?.absoluteString
            )
        }
    }
}

// MARK: - 🅾️ (수정) 공용 아바타 뷰로 통합

/// 기본 프로필 아이콘 (회색 배경 + 사람)
private struct DefaultAvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: "person.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.gray.opacity(0.6))
        }
    }
}

/// 1:1 채팅 프로필 이미지 (로직 통합)
struct ProfileAvatarView: View {
    let profileImage: String?
    let avatarURL: String?
    
    var body: some View {
        Group {
            // 1순위: Friend.profileImage (로컬 Asset)
            if let profileImage = profileImage, !profileImage.isEmpty {
                Image(profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
            // 2순위: Friend.avatarURL (서버 URL)
            else if let avatarURL = avatarURL, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    default:
                        DefaultAvatarView() // 실패 시 기본값
                    }
                }
            }
            // 3순위: 기본 아이콘
            else {
                DefaultAvatarView()
            }
        }
    }
}


// ❗️ (제거) 아래 뷰는 ProfileAvatarView로 대체되었으므로 삭제합니다.
// private struct ChatListProfileImage: View { ... }
