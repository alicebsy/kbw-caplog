import Foundation
import SwiftUI
import Combine

// MARK: - Local UI Models
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
extension ShareRepository { func markRead(threadId: String) async throws {} }

// MARK: - Mock Repository
struct MockShareRepository: ShareRepository {

    private var _friends: [Friend] {
        [
            .init(id: "u1", name: "민하", avatarURL: nil),
            .init(id: "u2", name: "다혜", avatarURL: nil),
            .init(id: "u3", name: "서연", avatarURL: nil),
            .init(id: "u4", name: "배우", avatarURL: nil)
        ]
    }

    // ✅ unreadCount를 클래스 변수로 유지 (상태 보존)
    private static var threadStates: [String: Int] = [
        "t1": 1,
        "t2": 0
    ]

    private var _threads: [ChatThread] {
        [
            .init(
                id: "t1",
                title: "민하",
                participantIds: ["me", "u1"],
                lastMessageText: "이번 주말 일정 공유했어!",
                lastMessageAt: Date().addingTimeInterval(-60 * 12),
                unreadCount: Self.threadStates["t1"] ?? 1
            ),
            .init(
                id: "t2",
                title: "강배우 팀",
                participantIds: ["me", "u1", "u2", "u3", "u4"],
                lastMessageText: "알겠습니다!",
                lastMessageAt: Date().addingTimeInterval(-60 * 5),
                unreadCount: Self.threadStates["t2"] ?? 0
            )
        ]
    }

    private static var messageStore: [String: [ChatMessage]] = [
        "t1": [
            .init(id: UUID().uuidString, senderId: "u1", text: "주말 일정 공유했어!", createdAt: Date().addingTimeInterval(-60*12))
        ],
        "t2": [
            .init(id: UUID().uuidString, senderId: "u2", text: "폴더 구조 정리 필요해", createdAt: Date().addingTimeInterval(-60*60*5)),
            .init(id: UUID().uuidString, senderId: "u3", text: "맞아, 체계적으로 정리하자", createdAt: Date().addingTimeInterval(-60*55)),
            .init(id: UUID().uuidString, senderId: "u1", text: "다음 주 목요일 가능할까?", createdAt: Date().addingTimeInterval(-60*50)),
            .init(id: UUID().uuidString, senderId: "me", text: "좋아! 함께 정리해보자", createdAt: Date().addingTimeInterval(-60*40)),
            .init(id: UUID().uuidString, senderId: "u4", text: "알겠습니다!", createdAt: Date().addingTimeInterval(-60*5))
        ]
    ]

    func fetchFriends() async throws -> [Friend] { _friends }
    func fetchChatThreads() async throws -> [ChatThread] { _threads }

    func fetchMessages(threadId: String) async throws -> [ChatMessage] {
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
        // ✅ unreadCount를 0으로 설정
        Self.threadStates[threadId] = 0
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
                participantIds: [],
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
    @Published private(set) var messagesByThread: [String: [ChatMessage]] = [:]

    @Published var searchKeyword: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repo: ShareRepository
    init(repo: ShareRepository) { self.repo = repo }

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let f = repo.fetchFriends()
            async let t = repo.fetchChatThreads()
            let (friends, threads) = try await (f, t)
            self.friends = friends
            self.threads = threads.sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    var filteredFriends: [Friend] {
        guard !searchKeyword.isEmpty else { return friends }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchKeyword) }
    }

    func openThread(_ threadId: String) async {
        do {
            let msgs = try await repo.fetchMessages(threadId: threadId)
            messagesByThread[threadId] = msgs
            
            // markRead 호출 - unreadCount를 0으로 설정
            try await repo.markRead(threadId: threadId)
            
            // UI 업데이트: threads 배열의 해당 항목 업데이트
            if let idx = threads.firstIndex(where: { $0.id == threadId }) {
                var updatedThread = threads[idx]
                updatedThread.unreadCount = 0
                threads[idx] = updatedThread
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func send(to threadId: String, text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let msg = try await repo.sendMessage(threadId: threadId, text: trimmed)
            var arr = messagesByThread[threadId] ?? []
            arr.append(msg)
            messagesByThread[threadId] = arr
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

    func timeString(for date: Date?) -> String {
        guard let date else { return "" }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "a h:mm"
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
