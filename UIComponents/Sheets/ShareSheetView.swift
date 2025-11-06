import SwiftUI

struct ShareFriend: Identifiable, Hashable {
    // ✅ (수정) ID 타입을 UUID에서 String으로 변경
    let id: String
    var name: String
    var avatar: String
}

/// 🔗 홈/폴더 어디서든 재사용 가능한 공유 시트
struct ShareSheetView<T: Identifiable>: View {
    let target: T
    let friends: [ShareFriend]
    // ✅ (수정) ID 타입을 UUID에서 String으로 변경
    var onSend: (_ selectedFriendIDs: [String], _ message: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    // ✅ (수정) ID 타입을 UUID에서 String으로 변경
    @State private var selectedIDs: Set<String> = []

    var body: some View {
        VStack(spacing: 16) {
            // 상단바
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

            // 친구 목록
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
                                    if selectedIDs.contains(f.id) {
                                        selectedIDs.remove(f.id)
                                    } else {
                                        selectedIDs.insert(f.id)
                                    }
                                }
                            Text(f.name)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 6)
            }

            // 메시지 입력
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
