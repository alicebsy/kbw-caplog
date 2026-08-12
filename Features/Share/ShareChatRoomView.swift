import SwiftUI

struct ChatRoomView: View {
    @ObservedObject var vm: ShareViewModel
    let thread: ChatThread
    
    @State private var inputText = ""
    @Environment(\.dismiss) var dismiss
    /// 현재 로그인한 유저의 userId.
    /// 예전에는 뷰가 만들어지는 순간 UserDefaults에서 한 번 읽어 저장해뒀는데,
    /// 프로필이 나중에 도착하면 계속 빈 값이라 내 메시지도 남의 것으로 보였습니다.
    private var meId: String { vm.currentUserId }

    @State private var showCardSelection = false
    @State private var showLeaveConfirm = false
    @State private var isInitialLoading = true
    @State private var isSendingMessage = false
    @State private var isSendingCards = false
    @State private var isLeavingChat = false
    /// 메시지 보내기·나가기처럼 사용자가 방금 누른 동작의 실패 (alert로 알림)
    @State private var operationError: String?
    /// 메시지 목록을 불러오지 못한 상태 (화면 안에 남겨두고 다시 시도를 받음).
    /// 예전엔 둘을 한 변수로 썼는데, alert가 뜨면서 "다시 시도" 버튼을 덮고
    /// alert를 닫으면 값이 지워져 버튼까지 같이 사라졌습니다.
    @State private var loadError: String?
    
    // 최초 진입 후 스크롤 한번만 강제 이동
    @State private var hasInitialScrolled = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    if isInitialLoading && groupedMessages.isEmpty {
                        ProgressView("메시지를 불러오는 중...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else if groupedMessages.isEmpty {
                        // 못 불러온 것과 아직 아무도 말을 안 한 것은 다릅니다.
                        if let loadError {
                            ContentUnavailableView {
                                Label("메시지를 불러오지 못했어요", systemImage: "wifi.exclamationmark")
                            } description: {
                                Text(loadError)
                            } actions: {
                                Button("다시 시도") {
                                    Task { await reloadMessages() }
                                }
                            }
                            .padding(.top, 48)
                        } else {
                            ContentUnavailableView {
                                Label("아직 메시지가 없어요", systemImage: "bubble.left.and.bubble.right")
                            } description: {
                                Text("첫 메시지를 보내 대화를 시작해 보세요.")
                            }
                            .padding(.top, 48)
                        }
                    } else {
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
                                        senderInfo: getSenderInfo(msg)
                                    )
                                    .id(msg.id)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                }
                .background(Color(uiColor: .systemGroupedBackground))
                
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
                .task(id: thread.id) {
                    let loaded = await vm.openThread(thread.id)
                    isInitialLoading = false
                    loadError = loaded ? nil : vm.errorMessage
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let lastId = vm.messagesByThread[thread.id]?.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                        hasInitialScrolled = true
                    }

                    while !Task.isCancelled {
                        do {
                            try await Task.sleep(for: .seconds(3))
                        } catch {
                            break
                        }
                        _ = await vm.refreshThreadMessages(thread.id)
                    }
                }
            }
            
            // --- 입력창 ---
            HStack(spacing: 8) {
                Button {
                    showCardSelection = true
                } label: {
                    Image(systemName: "plus")
                        .accessibilityLabel("카드 첨부")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Color.homeGreenLight.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isSendingCards || isLeavingChat)
                
                TextField("메시지 입력", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .systemGroupedBackground))
                    )
                    .submitLabel(.send)
                    .onSubmit { send() }
                    .disabled(isSendingMessage || isLeavingChat)
                
                Button("보내기") { send() }
                    .disabled(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || isSendingMessage
                            || isLeavingChat
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        // 카톡처럼 전체를 연한 회색 배경으로
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // 좌측: 커스텀 뒤로가기 버튼
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("뒤로")
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            // 중앙: 제목
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    Text(thread.title)
                        .font(.system(size: 16, weight: .semibold))
                    if thread.participantIds.count > 2 {
                        Text("\(thread.participantIds.count)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.brandTextSub)
                    }
                }
            }
            // 우측: 나가기
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLeaveConfirm = true
                } label: {
                    Group {
                        if isLeavingChat {
                            ProgressView()
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(Color.homeGreenTint.opacity(0.7))
                        }
                    }
                }
                .disabled(isLeavingChat || isSendingMessage || isSendingCards)
            }
        }
        // 채팅방 전체에 초록 계열 틴트 적용 (뒤로가기/보내기 등 기본 파랑 제거)
        .tint(Color.homeGreenTint)
        
        // 카드 선택 시트
        .sheet(isPresented: $showCardSelection) {
            ShareCardSelectionSheet { selectedCards in
                Task {
                    isSendingCards = true
                    defer { isSendingCards = false }
                    for card in selectedCards {
                        let sent = await vm.sendCard(to: thread.id, card: card)
                        if !sent {
                            operationError = vm.errorMessage
                            break
                        }
                    }
                }
            }
        }
        
        // 채팅방 나가기 경고창
        .alert("채팅방 나가기", isPresented: $showLeaveConfirm) {
            Button("취소", role: .cancel) {}
            Button("나가기", role: .destructive) {
                Task {
                    isLeavingChat = true
                    let left = await vm.leaveChat(threadId: thread.id)
                    isLeavingChat = false
                    if left {
                        dismiss()
                    } else {
                        operationError = vm.errorMessage
                    }
                }
            }
        } message: {
            Text("이 채팅방을 나가시겠습니까?\n내 채팅 목록에서 사라지며 다시 볼 수 없습니다.")
        }
        .alert("작업을 완료하지 못했어요", isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("확인", role: .cancel) { operationError = nil }
        } message: {
            Text(operationError ?? "")
        }
    }
    
    // MARK: - 메시지 전송
    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        Task {
            isSendingMessage = true
            let sent = await vm.send(to: thread.id, text: text)
            isSendingMessage = false
            if sent {
                inputText = ""
            } else {
                operationError = vm.errorMessage
            }
        }
    }

    private func reloadMessages() async {
        isInitialLoading = true
        let loaded = await vm.openThread(thread.id)
        isInitialLoading = false
        loadError = loaded ? nil : vm.errorMessage
    }
    
    // MARK: - 보낸 사람 정보
    private func getSenderInfo(_ message: ChatMessage) -> SenderInfo {
        if message.senderId == meId {
            return SenderInfo(name: "나", avatarURL: nil, profileImage: nil)
        }
        if let friend = vm.friends.first(where: { $0.id == message.senderId }) {
            return SenderInfo(
                name: friend.name,
                avatarURL: friend.avatarURL?.absoluteString,
                profileImage: friend.profileImage
            )
        }
        let serverName = message.senderName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = serverName.flatMap { $0.isEmpty ? nil : $0 } ?? "알 수 없음"
        return SenderInfo(
            name: displayName,
            avatarURL: nil,
            profileImage: nil
        )
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
    // DateFormatter를 만드는 건 꽤 비쌉니다. 예전엔 아래 세 함수가 호출될 때마다
    // 새로 만들었는데, groupedMessages가 메시지 하나당 한 번씩 부르는 데다
    // inputText가 이 화면의 @State라 글자를 칠 때마다 전부 다시 돌았습니다.
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 EEEE"
        return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"
        return f
    }()

    private func formatDate(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }
    private func parseDate(_ dateString: String) -> Date {
        Self.dayFormatter.date(from: dateString) ?? Date()
    }
    private func formatTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
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
            .foregroundColor(Color.homeGreenTint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.homeGreenLight.opacity(0.4)))
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
                    // .secondary는 흰 면에서 3.26:1이라 12pt 글자로는 AA 미달입니다.
                    Text(senderInfo.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.brandTextSub)
                        .padding(.horizontal, 4)
                }
                
                if let card = message.sharedCard
                    ?? message.cardID.flatMap({ vm.getCard(byId: $0) }) {
                    HStack(alignment: .bottom, spacing: 6) {
                        if isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.brandTextSub)
                                .padding(.bottom, 2)
                        }
                        
                        UnifiedCardView(card: card, style: .chat)
                        
                        if !isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.brandTextSub)
                                .padding(.bottom, 2)
                        }
                    }
                } else if let text = message.text {
                    HStack(alignment: .bottom, spacing: 6) {
                        if isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.brandTextSub)
                                .padding(.bottom, 2)
                        }
                        
                        Text(text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isMine ? Color.homeGreenDark : Color(uiColor: .secondarySystemGroupedBackground))
                            )
                            .foregroundColor(isMine ? .white : .primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isMine ? Color.clear : Color.homeGreenLight, lineWidth: 1)
                            )
                        
                        if !isMine {
                            Text(timeText)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.brandTextSub)
                                .padding(.bottom, 2)
                        }
                    }
                }
            }
            
            if !isMine {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}
