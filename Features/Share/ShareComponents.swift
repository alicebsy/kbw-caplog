import SwiftUI

// 친구 한 줄(이름만) 공용 컴포넌트
struct FriendRow: View {
    let name: String

    var body: some View {
        HStack(spacing: 12) {
            DefaultAvatarView()
            
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
            // 공용 뷰 사용
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
                .foregroundColor(isSelected ? .accentGreenTint : .gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - ✅ 선택 가능한 채팅방 행

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
                            .foregroundStyle(Color.brandTextSub)
                        Text(cardTitle)
                    } else {
                        Text(thread.lastMessageText ?? "...")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Color.brandTextSub)
                .lineLimit(1)
            }
            
            Spacer()
            
            // 체크박스
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .accentGreenTint : .gray.opacity(0.5))
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
                Circle().fill(Color.pointBlue.opacity(0.12))
                Text("\(thread.participantIds.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.pointBlue)
            }
            .frame(width: 40, height: 40)
        } else {
            // --- 1:1 채팅: 상대방 프로필 ---
            let otherParticipantID = thread.participantIds.first {
                $0 != "me" && $0 != vm.currentUserId
            }
            let friend = vm.friends.first(where: { $0.id == otherParticipantID })
            
            // 공용 뷰 사용
            ProfileAvatarView(
                profileImage: friend?.profileImage,
                avatarURL: friend?.avatarURL?.absoluteString
            )
        }
    }
}

// MARK: - 🅾️ 공용 아바타 뷰 (핵심)

/// 기본 프로필 아이콘 (회색 배경 + 사람)
private struct DefaultAvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2)) // 흰색이 아닌 회색 배경
                .frame(width: 40, height: 40)
            
            Image(systemName: "person.fill") // 사람 아이콘
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
            // ❗️ [수정] profileImage가 "avatar_default"가 아닌 실제 이미지 이름일 때만 로드
            if let profileImage = profileImage,
               !profileImage.isEmpty,
               profileImage != "avatar_default"
            {
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
                        DefaultAvatarView() // 로드 실패 시 기본값
                    }
                }
            }
            // 3순위: 기본 아이콘 (profileImage가 nil, "", 또는 "avatar_default"일 때)
            else {
                DefaultAvatarView()
            }
        }
    }
}
