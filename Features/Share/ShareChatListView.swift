import SwiftUI

final class ShareChatListVM: ObservableObject {
    @Published var chats: [ChatSummary] = []
    private let api = ShareAPI()

    @MainActor func load() async {
        do { chats = try await api.fetchChats() }
        catch {
            chats = [
                ChatSummary(id: "c1", title: "엄마", lastMessage: "송금 완료", updatedAt: .now, unreadCount: 2, avatarURL: nil),
                ChatSummary(id: "c2", title: "캡스톤 팀", lastMessage: "발표 준비 중", updatedAt: .now, unreadCount: 0, avatarURL: nil)
            ]
        }
    }
}

struct ShareChatListView: View {
    @StateObject private var vm = ShareChatListVM()

    var body: some View {
        List(vm.chats) { chat in
            NavigationLink {
                ShareChatRoomView(chat: chat)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(chat.title).font(.headline)
                        Spacer()
                        Text(chat.updatedAt, style: .time).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(chat.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .task { await vm.load() }
    }
}
