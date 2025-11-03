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
                    LazyVStack(spacing: 0) {
                        ForEach(groupedMessages) { group in
                            // ✅ 날짜 헤더 (카카오톡 스타일)
                            DateHeaderView(date: group.date)
                                .padding(.top, 24)      // ⬅️ 날짜 넘어갈 때 위 여백 확대
                                .padding(.bottom, 12)   // ⬅️ 아래 여백은 기존 유지
                            
                            // 해당 날짜의 메시지들
                            ForEach(group.messages) { msg in
                                MessageRow(
                                    meId: meId,
                                    message: msg,
                                    timeText: formatTime(msg.createdAt),
                                    senderInfo: getSenderInfo(msg.senderId)
                                )
                                .id(msg.id)
                                .padding(.vertical, 2)
                            }
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
        .task { await vm.openThread(thread.id) }
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task {
            await vm.send(to: thread.id, text: text)
            inputText = ""
        }
    }
    
    // ✅ 발신자 정보 가져오기
    private func getSenderInfo(_ senderId: String) -> SenderInfo {
        if senderId == meId {
            return SenderInfo(name: "나", avatarURL: nil)
        }
        
        if let friend = vm.friends.first(where: { $0.id == senderId }) {
            // 🔧 FIX: URL? -> String? 로 변환하여 타입 일치
            return SenderInfo(name: friend.name, avatarURL: friend.avatarURL?.absoluteString)
        }
        
        return SenderInfo(name: "알 수 없음", avatarURL: nil)
    }
    
    // ✅ 메시지를 날짜별로 그룹화
    private var groupedMessages: [MessageGroup] {
        let messages = vm.messagesByThread[thread.id] ?? []
        let calendar = Calendar.current
        
        // 날짜별로 그룹화
        var groups: [String: [ChatMessage]] = [:]
        
        for message in messages {
            let dateKey = formatDate(message.createdAt)
            if groups[dateKey] == nil {
                groups[dateKey] = []
            }
            groups[dateKey]?.append(message)
        }
        
        // MessageGroup으로 변환 후 날짜순 정렬
        return groups.map { key, messages in
            MessageGroup(
                id: key,
                date: key,
                messages: messages.sorted { $0.createdAt < $1.createdAt }
            )
        }.sorted { parseDate($0.date) < parseDate($1.date) }
    }
    
    // ✅ 날짜 포맷: "2014년 10월 5일 일요일"
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: date)
    }
    
    // ✅ 시간 포맷: "오전 10:51"
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
    
    // ✅ 문자열을 Date로 파싱 (정렬용)
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.date(from: dateString) ?? Date()
    }
}

// ✅ 날짜별 메시지 그룹
struct MessageGroup: Identifiable {
    let id: String
    let date: String
    let messages: [ChatMessage]
}

// ✅ 발신자 정보 구조체
struct SenderInfo {
    let name: String
    let avatarURL: String?
}

// ✅ 날짜 헤더 (카카오톡 스타일)
struct DateHeaderView: View {
    let date: String
    
    var body: some View {
        Text(date)
            .font(.system(size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.5))
            )
    }
}

// ✅ 프로필 + 이름 + 말풍선 + 시간 컴포넌트
struct MessageRow: View {
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
                // ✅ 상대방 메시지: 프로필 이미지
                VStack(spacing: 0) {
                    ProfileImage(avatarURL: senderInfo.avatarURL)
                    Spacer()
                }
            }
            
            // 메시지 영역
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                // ✅ 이름 표시 (상대방만)
                if !isMine {
                    Text(senderInfo.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                
                // 말풍선 + 시간
                HStack(alignment: .bottom, spacing: 6) {
                    if isMine {
                        // ✅ 내 메시지: 시간 왼쪽
                        Text(timeText)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                    }
                    
                    // 말풍선
                    Text(message.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isMine ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    if !isMine {
                        // ✅ 상대방 메시지: 시간 오른쪽
                        Text(timeText)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
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

// ✅ 재사용 가능한 프로필 이미지 컴포넌트
private struct ProfileImage: View {
    let avatarURL: String?
    
    var body: some View {
        Group {
            if let avatarURL = avatarURL, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
                // 실제 이미지 로드
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
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
