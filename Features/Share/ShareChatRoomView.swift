import SwiftUI
import Combine

struct ChatRoomView: View {
    @ObservedObject var vm: ShareViewModel
    let thread: ChatThread
    @State private var inputText = ""
    private let meId = "me"

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(vm.messagesByThread[thread.id] ?? []) { msg in
                            MessageRow(
                                meId: meId,
                                message: msg,
                                timeText: vm.timeString(for: msg.createdAt)
                            )
                            .id(msg.id)
                        }
                    }
                    .padding(.top, 12)
                }
                .onChange(of: vm.messagesByThread[thread.id]?.last?.id) { _, lastId in
                    if let lastId { withAnimation { proxy.scrollTo(lastId, anchor: .bottom) } }
                }
            }

            // 입력 바
            HStack(spacing: 8) {
                TextField("메시지 입력", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit { send() }

                Button("보내기") { send() }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .navigationTitle(thread.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.openThread(thread.id) } // 🔹 읽음 처리 + 메시지 로드
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task {
            await vm.send(to: thread.id, text: text)
            inputText = ""
        }
    }
}

// 🔹 말풍선 + 시간 컴포넌트
struct MessageRow: View {
    let meId: String
    let message: ChatMessage
    let timeText: String
    var isMine: Bool { message.senderId == meId }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine { Spacer(minLength: 32) }
            Text(message.text)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(isMine ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(timeText).font(.caption2).foregroundStyle(.secondary).padding(.bottom, 2).fixedSize()
            if !isMine { Spacer(minLength: 32) }
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
        .padding(.horizontal, 16).padding(.vertical, 2)
    }
}
