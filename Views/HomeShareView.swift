import SwiftUI

struct ShareFriend: Identifiable, Hashable {
    let id: UUID
    var name: String
    var avatar: String
}

struct HomeShareView: View {
    let target: Content
    let friends: [ShareFriend]
    var onSend: (_ selectedFriendIDs: [UUID], _ message: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var selectedIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("공유")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            // 친구 목록 (수평 캐러셀)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(friends) { f in
                        VStack(spacing: 6) {
                            Image(f.avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedIDs.contains(f.id) ? Color.brandAccent : .clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    if selectedIDs.contains(f.id) { selectedIDs.remove(f.id) }
                                    else { selectedIDs.insert(f.id) }
                                }
                            Text(f.name)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 6)
            }

            // 메시지 입력 + 전송 버튼
            HStack(spacing: 10) {
                TextField("메시지를 입력하세요", text: $message)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brandLine))
                Button {
                    onSend(Array(selectedIDs), message)
                    dismiss()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 48)
                        .background(Color.brandAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedIDs.isEmpty && message.isEmpty)
                .opacity((selectedIDs.isEmpty && message.isEmpty) ? 0.5 : 1)
            }
        }
        .padding(16)
        .background(Color.brandCardBG)
    }
}
