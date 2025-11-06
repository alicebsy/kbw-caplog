import SwiftUI

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

// ✅ (추가됨) 체크박스가 있는 친구 한 줄
// 이 뷰가 누락되어 컴파일 오류가 발생했습니다.
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
