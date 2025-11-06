import SwiftUI
import Combine

struct ChatRoomView: View {
    @ObservedObject var vm: ShareViewModel
    let thread: ChatThread
    @State private var inputText = ""
    @Environment(\.dismiss) var dismiss
    private let meId = "me"
    
    @State private var showCardSelection = false
    @State private var showLeaveConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedMessages) { group in
                            // 날짜 헤더
                            DateHeaderView(date: group.date)
                                .padding(.top, 12)
                                .padding(.bottom, 10)
                            
                            // 해당 날짜의 메시지들
                            ForEach(group.messages) { msg in
                                MessageRow(
                                    vm: vm,
                                    meId: meId,
                                    message: msg,
                                    timeText: formatTime(msg.createdAt),
                                    senderInfo: getSenderInfo(msg.senderId)
                                )
                                .id(msg.id)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .onChange(of: vm.messagesByThread[thread.id]?.last?.id) { _, lastId in
                    if let lastId { withAnimation { proxy.scrollTo(lastId, anchor: .bottom) } }
                }
            }

            // 입력 바
            HStack(spacing: 8) {
                // + 버튼
                Button {
                    showCardSelection = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
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
        .toolbar {
            // 중앙 제목 (참여자 수)
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    Text(thread.title)
                        .font(.system(size: 16, weight: .semibold))
                    if thread.participantIds.count > 2 {
                        Text("\(thread.participantIds.count)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // 나가기 버튼
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLeaveConfirm = true
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task { await vm.openThread(thread.id) }
        .sheet(isPresented: $showCardSelection) {
            ShareCardSelectionSheet { selectedCards in
                Task {
                    for card in selectedCards {
                        await vm.sendCard(to: thread.id, card: card)
                    }
                }
            }
        }
        .alert("채팅방 나가기", isPresented: $showLeaveConfirm) {
            Button("취소", role: .cancel) { }
            Button("나가기", role: .destructive) {
                Task {
                    await vm.leaveChat(threadId: thread.id)
                    dismiss()
                }
            }
        } message: {
            Text("이 채팅방을 나가시겠습니까?\n대화 내용이 모두 삭제됩니다.")
        }
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task {
            await vm.send(to: thread.id, text: text)
            inputText = ""
        }
    }
    
    private func getSenderInfo(_ senderId: String) -> SenderInfo {
        if senderId == meId {
            return SenderInfo(name: "나", avatarURL: nil)
        }
        if let friend = vm.friends.first(where: { $0.id == senderId }) {
            return SenderInfo(name: friend.name, avatarURL: friend.avatarURL?.absoluteString)
        }
        return SenderInfo(name: "알 수 없음", avatarURL: nil)
    }
    
    // ... (groupedMessages, formatDate, formatTime, parseDate 함수는 변경 없음) ...
    private var groupedMessages: [MessageGroup] {
        let messages = vm.messagesByThread[thread.id] ?? []
        _ = Calendar.current
        var groups: [String: [ChatMessage]] = [:]
        for message in messages {
            let dateKey = formatDate(message.createdAt)
            if groups[dateKey] == nil {
                groups[dateKey] = []
            }
            groups[dateKey]?.append(message)
        }
        return groups.map { key, messages in
            MessageGroup(
                id: key,
                date: key,
                messages: messages.sorted { $0.createdAt < $1.createdAt }
            )
        }.sorted { parseDate($0.date) < parseDate($1.date) }
    }
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: date)
    }
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.date(from: dateString) ?? Date()
    }
}

// ... (MessageGroup, SenderInfo, DateHeaderView 정의는 변경 없음) ...
struct MessageGroup: Identifiable {
    let id: String
    let date: String
    let messages: [ChatMessage]
}
struct SenderInfo {
    let name: String
    let avatarURL: String?
}
struct DateHeaderView: View {
    let date: String
    var body: some View {
        Text(date)
            .font(.system(size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.gray.opacity(0.5)))
    }
}


// MARK: - MessageRow

struct MessageRow: View {
    let vm: ShareViewModel
    let meId: String
    let message: ChatMessage
    let timeText: String
    let senderInfo: SenderInfo
    
    var isMine: Bool { message.senderId == meId }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isMine {
                Spacer(minLength: 60)
            } else {
                VStack(spacing: 0) {
                    ProfileImage(avatarURL: senderInfo.avatarURL)
                    Spacer()
                }
            }
            
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                if !isMine {
                    Text(senderInfo.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                
                if let cardID = message.cardID, let card = vm.getCard(byId: cardID) {
                    
                    // --- 카드 메시지 ---
                    HStack(alignment: .bottom, spacing: 6) {
                        if isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)
                                .layoutPriority(1) // ✅ (추가)
                        }
                        
                        UnifiedCardView(card: card, style: .chat)
                            // ❌ (제거) .frame(width: 200)
                            .onTapGesture {
                                print("Tapped card: \(card.title)")
                            }
                        
                        if !isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)
                                .layoutPriority(1) // ✅ (추가)
                        }
                    }
                    
                } else if let text = message.text {
                    
                    // --- 텍스트 메시지 (기존과 동일) ---
                    HStack(alignment: .bottom, spacing: 6) {
                        if isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)
                        }
                        
                        Text(text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isMine ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        if !isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)
                        }
                    }
                }
            }
            
            if !isMine {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
    }
}

// ... (ProfileImage 정의는 변경 없음) ...
private struct ProfileImage: View {
    let avatarURL: String?
    var body: some View {
        Group {
            if let avatarURL = avatarURL, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_), .empty:
                        defaultAvatar
                    @unknown default:
                        defaultAvatar
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                defaultAvatar
            }
        }
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
