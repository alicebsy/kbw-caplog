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
    
    // 최초 진입 후 스크롤 한번만 강제 이동
    @State private var hasInitialScrolled = false
    
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
                            
                            // 해당 날짜 메시지들
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
                
                // 1) 메시지가 추가될 때마다 최신 메시지로 이동
                .onChange(of: vm.messagesByThread[thread.id]?.last?.id) { _, lastId in
                    guard let lastId else { return }
                    // 뷰 업데이트 뒤에 이동해야 안정적
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.12)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                
                // 2) 최초 진입 시 한번만 최신 메시지로 이동
                .onChange(of: vm.messagesByThread[thread.id]?.count) { _, _ in
                    guard !hasInitialScrolled else { return }
                    hasInitialScrolled = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let lastId = vm.messagesByThread[thread.id]?.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                
                // 3) ChatRoom 진입 시 메시지 로드 → 최신 메시지로 이동
                .task {
                    await vm.openThread(thread.id)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let lastId = vm.messagesByThread[thread.id]?.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                        hasInitialScrolled = true
                    }
                }
            }
            
            // --- 입력창 ---
            HStack(spacing: 8) {
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
        
        // 상단 툴바
        .toolbar {
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
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLeaveConfirm = true
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        // 카드 선택 시트
        .sheet(isPresented: $showCardSelection) {
            ShareCardSelectionSheet { selectedCards in
                Task {
                    for card in selectedCards {
                        await vm.sendCard(to: thread.id, card: card)
                    }
                }
            }
        }
        
        // 채팅방 나가기 경고창
        .alert("채팅방 나가기", isPresented: $showLeaveConfirm) {
            Button("취소", role: .cancel) {}
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
    
    // MARK: - 메시지 전송
    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        Task {
            await vm.send(to: thread.id, text: text)
            inputText = ""
        }
    }
    
    // MARK: - 보낸 사람 정보
    private func getSenderInfo(_ senderId: String) -> SenderInfo {
        if senderId == meId {
            return SenderInfo(name: "나", avatarURL: nil, profileImage: nil)
        }
        if let friend = vm.friends.first(where: { $0.id == senderId }) {
            return SenderInfo(
                name: friend.name,
                avatarURL: friend.avatarURL?.absoluteString,
                profileImage: friend.profileImage
            )
        }
        return SenderInfo(name: "알 수 없음", avatarURL: nil, profileImage: nil)
    }
    
    // MARK: - 메시지 그룹화
    private var groupedMessages: [MessageGroup] {
        let messages = vm.messagesByThread[thread.id] ?? []
        var groups: [String: [ChatMessage]] = [:]
        
        for msg in messages {
            let key = formatDate(msg.createdAt)
            groups[key, default: []].append(msg)
        }
        
        return groups
            .map { key, msgs in
                MessageGroup(
                    id: key,
                    date: key,
                    messages: msgs.sorted { $0.createdAt < $1.createdAt }
                )
            }
            .sorted { parseDate($0.date) < parseDate($1.date) }
    }
    
    // MARK: - 날짜 관련
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 EEEE"
        return f.string(from: date)
    }
    private func parseDate(_ dateString: String) -> Date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 EEEE"
        return f.date(from: dateString) ?? Date()
    }
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"
        return f.string(from: date)
    }
}


// MARK: - Supporting Types

struct MessageGroup: Identifiable {
    let id: String
    let date: String
    let messages: [ChatMessage]
}

struct SenderInfo {
    let name: String
    let avatarURL: String?
    let profileImage: String?
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


// MARK: - MessageRow (너가 준 코드 그대로 사용됨)
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
                    ProfileAvatarView(
                        profileImage: senderInfo.profileImage,
                        avatarURL: senderInfo.avatarURL
                    )
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
                    HStack(alignment: .bottom, spacing: 6) {
                        if isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)
                        }
                        
                        UnifiedCardView(card: card, style: .chat)
                        
                        if !isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)
                        }
                    }
                } else if let text = message.text {
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
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        
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
