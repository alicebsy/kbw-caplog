import SwiftUI

final class ShareChatRoomVM: ObservableObject {
    @Published var messages: [Message] = []
    @Published var text: String = ""
    private let api = ShareAPI()
    let chat: ChatSummary

    init(chat: ChatSummary) { self.chat = chat }

    @MainActor func load() async {
        do { messages = try await api.fetchMessages(chatId: chat.id) }
        catch {
            messages = [
                Message(id: "1", chatId: chat.id, senderId: "1", senderName: "엄마", text: "송금했어", createdAt: .now),
                Message(id: "2", chatId: chat.id, senderId: "me", senderName: "나", text: "고마워요 💛", createdAt: .now)
            ]
        }
    }

    @MainActor func send() async {
        guard !text.isEmpty else { return }
        messages.append(Message(id: UUID().uuidString, chatId: chat.id, senderId: "me", senderName: "나", text: text, createdAt: .now))
        text = ""
    }
}

struct ShareChatRoomView: View {
    @StateObject private var vm: ShareChatRoomVM
    init(chat: ChatSummary) {
        _vm = StateObject(wrappedValue: ShareChatRoomVM(chat: chat))
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(vm.messages) { msg in
                        HStack {
                            if msg.senderId == "me" { Spacer() }
                            Text(msg.text)
                                .padding()
                                .background(msg.senderId == "me" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            if msg.senderId != "me" { Spacer() }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 2)
                    }
                }
            }

            HStack {
                TextField("메시지 입력", text: $vm.text)
                    .textFieldStyle(.roundedBorder)
                Button("보내기") {
                    Task { await vm.send() }
                }
            }
            .padding()
        }
        .navigationTitle(vm.chat.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }
}
