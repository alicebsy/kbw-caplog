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
