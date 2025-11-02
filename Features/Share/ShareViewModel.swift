import Foundation
import SwiftUI
import Combine

// MARK: - Model
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date
}

struct ChatThread: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var participantIds: [String]
    var lastMessageText: String?
    var lastMessageAt: Date?
    var unreadCount: Int
}

// MARK: - Repository Protocol
protocol ShareRepository {
    func fetchFriends() async throws -> [Friend]
    func fetchChatThreads() async throws -> [ChatThread]
    func fetchMessages(threadId: String) async throws -> [ChatMessage]
    func sendMessage(threadId: String, text: String) async throws -> ChatMessage
    func markRead(threadId: String) async throws
}

extension ShareRepository {
    // 라이브 연동 전엔 no-op
    func markRead(threadId: String) async throws {}
}

// MARK: - Mock Repository
struct MockShareRepository: ShareRepository {

    private var _friends: [Friend] {
        [
            .init(id: "u1", name: "민하", status: "online",  avatarURL: nil),
            .init(id: "u2", name: "다혜", status: "offline", avatarURL: nil),
            .init(id: "u3", name: "서연", status: "online",  avatarURL: nil),
            .init(id: "u4", name: "배우", status: "offline", avatarURL: nil)
        ]
    }

    // 샘플 스레드
    private var _threads: [ChatThread] {
        [
            .init(
                id: "t1",
                title: "민하",
                participantIds: ["u1"],
                lastMessageText: "이번 주말 일정 공유했어!",
                lastMessageAt: Date().addingTimeInterval(-60 * 12), // 12분 전
                unreadCount: 1
            ),
            .init(
                id: "t2",
                title: "강배우 팀",
                participantIds: ["u1", "u2", "u3"],
                lastMessageText: "폴더 구조 정리 완료",
                lastMessageAt: Date().addingTimeInterval(-60 * 60 * 5), // 5시간 전
                unreadCount: 0
            )
        ]
    }

    // 스레드별 메시지 모킹
    private static var messageStore: [String: [ChatMessage]] = [
        "t1": [
            .init(id: UUID().uuidString, senderId: "u1", text: "주말 일정 공유했어!", createdAt: Date().addingTimeInterval(-60*12))
        ],
        "t2": [
            .init(id: UUID().uuidString, senderId: "u2", text: "폴더 구조 정리 완료", createdAt: Date().addingTimeInterval(-60*60*5))
        ]
    ]

    func fetchFriends() async throws -> [Friend] { _friends }

    func fetchChatThreads() async throws -> [ChatThread] { _threads }

    func fetchMessages(threadId: String) async throws -> [ChatMessage] {
        // 네트워크 지연 흉내
        try? await Task.sleep(nanoseconds: 200_000_000)
        return Self.messageStore[threadId] ?? []
    }

    func sendMessage(threadId: String, text: String) async throws -> ChatMessage {
        let msg = ChatMessage(id: UUID().uuidString, senderId: "me", text: text, createdAt: Date())
        var arr = Self.messageStore[threadId] ?? []
        arr.append(msg)
        Self.messageStore[threadId] = arr
        return msg
    }

    func markRead(threadId: String) async throws {
        // 더미: 아무 것도 안 함
    }
}

// MARK: - Live Repository (Firebase / API)
struct LiveShareRepository: ShareRepository {
    private let api = ShareAPI()

    func fetchFriends() async throws -> [Friend] {
        try await api.fetchFriends()
    }

    func fetchChatThreads() async throws -> [ChatThread] {
        let summaries = try await api.fetchChats()
        return summaries.map { s in
            ChatThread(
                id: s.id,
                title: s.title,
                participantIds: [],              // 필요 시 채우기
                lastMessageText: s.lastMessage,
                lastMessageAt: s.updatedAt,
                unreadCount: s.unreadCount
            )
        }
    }

    func fetchMessages(threadId: String) async throws -> [ChatMessage] {
        let items = try await api.fetchMessages(chatId: threadId)
        return items.map { m in
            ChatMessage(id: m.id, senderId: m.senderId, text: m.text, createdAt: m.createdAt)
        }
    }

    func sendMessage(threadId: String, text: String) async throws -> ChatMessage {
        let m = try await api.sendMessage(chatId: threadId, text: text)
        return ChatMessage(id: m.id, senderId: m.senderId, text: m.text, createdAt: m.createdAt)
    }

    func markRead(threadId: String) async throws {
        try await api.markRead(chatId: threadId)
    }
}

// MARK: - ViewModel
@MainActor
final class ShareViewModel: ObservableObject {
    @Published private(set) var friends: [Friend] = []
    @Published private(set) var threads: [ChatThread] = []
    /// 채팅방별 메시지 캐시
    @Published private(set) var messagesByThread: [String: [ChatMessage]] = [:]

    @Published var searchKeyword: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repo: ShareRepository

    init(repo: ShareRepository) { self.repo = repo }

    // 전체 목록 로드
    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let f = repo.fetchFriends()
            async let t = repo.fetchChatThreads()
            let (friends, threads) = try await (f, t)
            self.friends = friends
            // 최신순 정렬(옵션)
            self.threads = threads.sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    var filteredFriends: [Friend] {
        guard !searchKeyword.isEmpty else { return friends }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchKeyword) }
    }

    // 채팅방 입장: 메시지 로드 + 읽음 처리
    func openThread(_ threadId: String) async {
        do {
            let msgs = try await repo.fetchMessages(threadId: threadId)
            messagesByThread[threadId] = msgs

            // 읽음 처리: 배지 0으로
            if let idx = threads.firstIndex(where: { $0.id == threadId }) {
                threads[idx].unreadCount = 0
            }
            try await repo.markRead(threadId: threadId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // 메시지 전송
    func send(to threadId: String, text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let msg = try await repo.sendMessage(threadId: threadId, text: trimmed)

            // 로컬 메시지 갱신
            var arr = messagesByThread[threadId] ?? []
            arr.append(msg)
            messagesByThread[threadId] = arr

            // 목록 최상단으로 올리고 내용/시간 업데이트
            if let idx = threads.firstIndex(where: { $0.id == threadId }) {
                var t = threads.remove(at: idx)
                t.lastMessageText = msg.text
                t.lastMessageAt = msg.createdAt
                t.unreadCount = 0
                threads.insert(t, at: 0)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // 목록 우측의 “작은 시간 텍스트” 포맷터
    func timeString(for date: Date?) -> String {
        guard let date else { return "" }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "a h:mm"   // 예: 오전 6:09
            return f.string(from: date)
        } else if cal.isDate(date, equalTo: Date(), toGranularity: .year) {
            let f = DateFormatter()
            f.dateFormat = "M/d"
            return f.string(from: date)
        } else {
            let f = DateFormatter()
            f.dateFormat = "yy/M/d"
            return f.string(from: date)
        }
    }
}
