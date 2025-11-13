import Foundation
import SwiftUI
import Combine

// ... (ChatMessage, ChatThread 정의는 변경 없음) ...
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let senderId: String
    let createdAt: Date
    let text: String?
    let cardID: UUID?
    
    init(id: String = UUID().uuidString, senderId: String, text: String?, cardID: UUID?, createdAt: Date = Date()) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.cardID = cardID
        self.createdAt = createdAt
    }
}
struct ChatThread: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var participantIds: [String]
    var lastMessageText: String?
    var lastMessageAt: Date?
    var unreadCount: Int
    var lastMessageCardTitle: String?
}

// ... (ShareRepository 프로토콜 정의는 변경 없음) ...
protocol ShareRepository {
    func fetchFriends() async throws -> [Friend]
    func fetchChatThreads() async throws -> [ChatThread]
    func fetchMessages(threadId: String) async throws -> [ChatMessage]
    func sendMessage(threadId: String, text: String?, cardID: UUID?) async throws -> ChatMessage
    func markRead(threadId: String) async throws
    func leaveChat(threadId: String) async throws
}
extension ShareRepository {
    func markRead(threadId: String) async throws {}
    func leaveChat(threadId: String) async throws {}
}

// MARK: - Mock Repository
final class MockShareRepository: ShareRepository {
    
    // ✅ (추가) 싱글톤 인스턴스
    static let shared = MockShareRepository()
    
    // ... (ID 정의는 변경 없음) ...
    private static let minhaID = FriendManager.mockFriends.first(where: { $0.name == "우민하" })!.id
    private static let dahyeID = FriendManager.mockFriends.first(where: { $0.name == "강다혜" })!.id
    private static let seoyeonID = FriendManager.mockFriends.first(where: { $0.name == "배서연" })!.id
    private static let yiwhaID = FriendManager.mockFriends.first(where: { $0.name == "김이화" })!.id
    private static let actorID = FriendManager.mockFriends.first(where: { $0.name == "김배우" })!.id
    private static let junghoonID = FriendManager.mockFriends.first(where: { $0.name == "이정훈" })!.id
    private static let jiaID = FriendManager.mockFriends.first(where: { $0.name == "송지아" })!.id
    private static let sujinID = FriendManager.mockFriends.first(where: { $0.name == "박수진" })!.id
    private static let yurimID = FriendManager.mockFriends.first(where: { $0.name == "신유림" })!.id
    private static let chaewonID = FriendManager.mockFriends.first(where: { $0.name == "임채원" })!.id
    private static let hayoonID = FriendManager.mockFriends.first(where: { $0.name == "정하윤" })!.id
    private static let junyoungID = FriendManager.mockFriends.first(where: { $0.name == "최준영" })!.id
    private static let jiwooID = FriendManager.mockFriends.first(where: { $0.name == "한지우" })!.id
    private static let inseongID = FriendManager.mockFriends.first(where: { $0.name == "황인성" })!.id
    private static let hongjieunID = FriendManager.mockFriends.first(where: { $0.name == "홍지은" })!.id
    
    private var _threads: [ChatThread] = []
    private var messageStore: [String: [ChatMessage]] = [:]

    // ✅ (수정) init을 private으로 변경
    private init() {
        // --- 1. 메시지 저장소(messageStore) 정의 ---
        
        let t1Messages: [ChatMessage] = [
            .init(senderId: "me", text: "민하야 혹시 스벅 쿠폰 필요해?", cardID: nil, createdAt: Date().addingTimeInterval(-60*12)),
            .init(senderId: "me", text: nil, cardID: MockCardIDs.starbucksCoupon, createdAt: Date().addingTimeInterval(-60*11)),
            .init(senderId: Self.minhaID, text: "오! 나 완전 필요해 고마워", cardID: nil, createdAt: Date().addingTimeInterval(-60*10))
        ]
        let t2Messages: [ChatMessage] = [
            .init(senderId: Self.dahyeID, text: "여기 가볼래?", cardID: MockCardIDs.makguksu, createdAt: Date().addingTimeInterval(-60*21)),
            .init(senderId: Self.dahyeID, text: "속초에 새로 생긴 곳인데 리뷰 좋아", cardID: nil, createdAt: Date().addingTimeInterval(-60*20)),
            .init(senderId: "me", text: "와 대박 ㅠㅠ 나 막국수 킬러잖아", cardID: nil, createdAt: Date().addingTimeInterval(-60*19)),
            .init(senderId: "me", text: "이번 주말에 바로 간다", cardID: nil, createdAt: Date().addingTimeInterval(-60*18))
        ]
        let t3Messages: [ChatMessage] = [
            .init(senderId: Self.seoyeonID, text: "이거 읽어봤어?", cardID: nil, createdAt: Date().addingTimeInterval(-60*31)),
            .init(senderId: Self.seoyeonID, text: nil, cardID: MockCardIDs.sentence, createdAt: Date().addingTimeInterval(-60*30)),
            .init(senderId: "me", text: "오... '너무 늦은 시도란 없다'", cardID: nil, createdAt: Date().addingTimeInterval(-60*29)),
            .init(senderId: "me", text: "좋은 글귀다 저장할게!", cardID: nil, createdAt: Date().addingTimeInterval(-60*28))
        ]
        let t4Messages: [ChatMessage] = [
            .init(senderId: "me", text: "저번에 말한 낭만식탁", cardID: MockCardIDs.nangman, createdAt: Date().addingTimeInterval(-60*40)),
            .init(senderId: "me", text: "여기 진짜 맛있더라", cardID: nil, createdAt: Date().addingTimeInterval(-60*39)),
            .init(senderId: Self.yiwhaID, text: "아 여기! 나도 가봤어. 사케동 인정", cardID: nil, createdAt: Date().addingTimeInterval(-60*38))
        ]
        let t5Messages: [ChatMessage] = [
            .init(senderId: Self.dahyeID, text: "얘들아 올영 세일한대", cardID: MockCardIDs.oliveYoungCoupon, createdAt: Date().addingTimeInterval(-60*9)),
            .init(senderId: Self.seoyeonID, text: "오 대박", cardID: nil, createdAt: Date().addingTimeInterval(-60*8)),
            .init(senderId: Self.minhaID, text: "이거 사야겠다", cardID: nil, createdAt: Date().addingTimeInterval(-60*7)),
            .init(senderId: Self.yiwhaID, text: "나도!!", cardID: nil, createdAt: Date().addingTimeInterval(-60*6)),
            .init(senderId: Self.dahyeID, text: "빨리 사", cardID: nil, createdAt: Date().addingTimeInterval(-60*5))
        ]
        let t6Messages: [ChatMessage] = {
            var messages: [ChatMessage] = []
            messages.append(.init(senderId: Self.actorID, text: "다음 회의 장소 정했습니다.", cardID: nil, createdAt: Date().addingTimeInterval(-60*1000)))
            messages.append(.init(senderId: Self.actorID, text: "여기서 하죠", cardID: MockCardIDs.cafeEround, createdAt: Date().addingTimeInterval(-60*999)))
            for i in 1...98 {
                messages.append(.init(senderId: Self.junghoonID, text: "확인했습니다. \(i)", cardID: nil, createdAt: Date().addingTimeInterval(-60*Double(900 - i))))
            }
            messages.append(.init(senderId: Self.minhaID, text: "네 저도 봤습니다.", cardID: nil, createdAt: Date().addingTimeInterval(-60*15)))
            return messages
        }()
        let t7Messages: [ChatMessage] = [
            .init(senderId: Self.dahyeID, text: nil, cardID: MockCardIDs.exhibition, createdAt: Date().addingTimeInterval(-60*26)),
            .init(senderId: Self.dahyeID, text: "성수동 전시회래. 이번 주말 어때?", cardID: nil, createdAt: Date().addingTimeInterval(-60*25)),
            .init(senderId: "me", text: "오 좋아좋아", cardID: nil, createdAt: Date().addingTimeInterval(-60*24)),
            .init(senderId: Self.jiaID, text: "저도 콜!", cardID: nil, createdAt: Date().addingTimeInterval(-60*23))
        ]
        let t8Messages: [ChatMessage] = [
            .init(senderId: Self.seoyeonID, text: "여기 평점 좋아", cardID: MockCardIDs.nangman, createdAt: Date().addingTimeInterval(-60*35)),
            .init(senderId: "me", text: "오 아까 이화도 여기 말했는데", cardID: nil, createdAt: Date().addingTimeInterval(-60*34)),
            .init(senderId: Self.sujinID, text: "결정? 7시 ㄱㄱ", cardID: nil, createdAt: Date().addingTimeInterval(-60*33))
        ]
        let t9Messages: [ChatMessage] = [
            .init(senderId: "me", text: "오늘 치킨 ㄱ?", cardID: MockCardIDs.chickenCoupon, createdAt: Date().addingTimeInterval(-60*46)),
            .init(senderId: Self.minhaID, text: "와 미쳤다", cardID: nil, createdAt: Date().addingTimeInterval(-60*45)),
            .init(senderId: Self.chaewonID, text: "콜콜콜", cardID: nil, createdAt: Date().addingTimeInterval(-60*44)),
            .init(senderId: Self.hayoonID, text: "저 지금 집 가요", cardID: nil, createdAt: Date().addingTimeInterval(-60*43)),
            .init(senderId: "me", text: "오케이 8시 주문?", cardID: nil, createdAt: Date().addingTimeInterval(-60*42))
        ]
        let t10Messages: [ChatMessage] = [
            .init(senderId: Self.dahyeID, text: nil, cardID: MockCardIDs.makguksu, createdAt: Date().addingTimeInterval(-60*56)),
            .init(senderId: Self.dahyeID, text: "속초 가면 여기 꼭 가", cardID: nil, createdAt: Date().addingTimeInterval(-60*55)),
            .init(senderId: Self.junyoungID, text: "오 저장", cardID: nil, createdAt: Date().addingTimeInterval(-60*54)),
            .init(senderId: Self.jiwooID, text: "와 맛있겠다", cardID: nil, createdAt: Date().addingTimeInterval(-60*53)),
            .init(senderId: "me", text: "나도 여기 저장함!", cardID: nil, createdAt: Date().addingTimeInterval(-60*52))
        ]
        self.messageStore = [
            "t1": t1Messages, "t2": t2Messages, "t3": t3Messages, "t4": t4Messages,
            "t5": t5Messages, "t6": t6Messages, "t7": t7Messages, "t8": t8Messages,
            "t9": t9Messages, "t10": t10Messages
        ]
        
        // --- 2. 채팅방(_threads) 정의 ---
        let getUnreadCount = { (id: String) -> Int in
            let messages = self.messageStore[id] ?? []
            return messages.filter { $0.senderId != "me" }.count
        }
        self._threads = [
            .init(id: "t1", title: "", participantIds: ["me", Self.minhaID],
                  lastMessageText: t1Messages.last?.text, lastMessageAt: t1Messages.last?.createdAt,
                  unreadCount: getUnreadCount("t1"),
                  lastMessageCardTitle: t1Messages.last?.cardID != nil ? "무료 음료 쿠폰" : nil),
            .init(id: "t2", title: "", participantIds: ["me", Self.dahyeID],
                  lastMessageText: t2Messages.last?.text, lastMessageAt: t2Messages.last?.createdAt,
                  unreadCount: 0, lastMessageCardTitle: nil),
            .init(id: "t3", title: "", participantIds: ["me", Self.seoyeonID],
                  lastMessageText: t3Messages.last?.text, lastMessageAt: t3Messages.last?.createdAt,
                  unreadCount: 0, lastMessageCardTitle: nil),
            .init(id: "t4", title: "", participantIds: ["me", Self.yiwhaID],
                  lastMessageText: t4Messages.last?.text, lastMessageAt: t4Messages.last?.createdAt,
                  unreadCount: 0, lastMessageCardTitle: t4Messages.last?.cardID != nil ? "낭만식탁" : nil),
            .init(id: "t5", title: "", participantIds: ["me", Self.dahyeID, Self.seoyeonID, Self.minhaID, Self.yiwhaID],
                  lastMessageText: t5Messages.last?.text, lastMessageAt: t5Messages.last?.createdAt,
                  unreadCount: getUnreadCount("t5"),
                  lastMessageCardTitle: t5Messages.last?.cardID != nil ? "올리브영 10% 할인" : nil),
            .init(id: "t6", title: "", participantIds: ["me", Self.actorID, Self.junghoonID, Self.minhaID],
                  lastMessageText: t6Messages.last?.text, lastMessageAt: t6Messages.last?.createdAt,
                  unreadCount: getUnreadCount("t6"), lastMessageCardTitle: nil),
            .init(id: "t7", title: "", participantIds: ["me", Self.dahyeID, Self.jiaID],
                  lastMessageText: t7Messages.last?.text, lastMessageAt: t7Messages.last?.createdAt,
                  unreadCount: 0, lastMessageCardTitle: t7Messages.last?.cardID != nil ? "AI와 미래 전시회" : nil),
            .init(id: "t8", title: "", participantIds: ["me", Self.seoyeonID, Self.sujinID],
                  lastMessageText: t8Messages.last?.text, lastMessageAt: t8Messages.last?.createdAt,
                  unreadCount: 0, lastMessageCardTitle: t8Messages.last?.cardID != nil ? "낭만식탁" : nil),
            .init(id: "t9", title: "", participantIds: ["me", Self.minhaID, Self.chaewonID, Self.hayoonID],
                  lastMessageText: t9Messages.last?.text, lastMessageAt: t9Messages.last?.createdAt,
                  unreadCount: 0, lastMessageCardTitle: t9Messages.last?.cardID != nil ? "BBQ 황금올리브 치킨 할인" : nil),
            .init(id: "t10", title: "", participantIds: ["me", Self.dahyeID, Self.junyoungID, Self.jiwooID],
                  lastMessageText: t10Messages.last?.text, lastMessageAt: t10Messages.last?.createdAt,
                  unreadCount: 0, lastMessageCardTitle: t10Messages.last?.cardID != nil ? "속초 막국수 맛집" : nil)
        ]
    }
    
    // ✅ (수정) FriendManager.toFriend()를 사용하여 profileImage 포함
    func fetchFriends() async throws -> [Friend] {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return FriendManager.mockFriends.map { shareFriend in
            FriendManager.toFriend(shareFriend)
        }
    }
    
    func fetchChatThreads() async throws -> [ChatThread] {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return _threads
    }
    
    func fetchMessages(threadId: String) async throws -> [ChatMessage] {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return messageStore[threadId] ?? []
    }
    
    func sendMessage(threadId: String, text: String?, cardID: UUID?) async throws -> ChatMessage {
        try? await Task.sleep(nanoseconds: 100_000_000)
        let newMsg = ChatMessage(senderId: "me", text: text, cardID: cardID, createdAt: Date())
        var arr = messageStore[threadId] ?? []
        arr.append(newMsg)
        messageStore[threadId] = arr
        
        if let idx = _threads.firstIndex(where: { $0.id == threadId }) {
            _threads[idx].lastMessageText = text
            _threads[idx].lastMessageAt = newMsg.createdAt
        }
        return newMsg
    }
    
    func markRead(threadId: String) async throws {
        if let idx = _threads.firstIndex(where: { $0.id == threadId }) {
            _threads[idx].unreadCount = 0
        }
    }
    
    func leaveChat(threadId: String) async throws {
        _threads.removeAll { $0.id == threadId }
        messageStore.removeValue(forKey: threadId)
    }
}

// MARK: - ShareViewModel (전역 싱글톤)

@MainActor
final class ShareViewModel: ObservableObject {
    
    nonisolated static let shared = ShareViewModel()
    
    @Published var friends: [Friend] = []
    @Published var threads: [ChatThread] = []
    @Published var messagesByThread: [String: [ChatMessage]] = [:]
    
    @Published var isLoading: Bool = false
    
    @Published var errorMessage: String?
    @Published var searchKeyword: String = ""
    
    // ❗️ [수정] nonisolated init에서 초기화되므로 이 속성들도 nonisolated로 변경
    private nonisolated let repo: ShareRepository
    private nonisolated let cardManager = CardManager.shared
    
    private nonisolated init(repo: ShareRepository = MockShareRepository.shared) {
        self.repo = repo
    }

    func loadAll() async {
        await loadFriends()
        await loadThreads()
    }
    
    private func loadFriends() async {
        do {
            self.friends = try await repo.fetchFriends()
            
            // ✅ (수정) 가나다순 정렬
            self.friends.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
            
            print("✅ ShareViewModel: \(friends.count)명 친구 로드 완료 (가나다순 정렬)")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    private func loadThreads() async {
        do {
            var fetchedThreads = try await repo.fetchChatThreads()
            
            for i in 0..<fetchedThreads.count {
                var thread = fetchedThreads[i]
                
                // 1. 참여자 이름 목록 (가나다순)
                let participantNames = thread.participantIds.compactMap { id -> String? in
                    guard id != "me" else { return nil }
                    return self.friends.first(where: { $0.id == id })?.name
                }
                .sorted()
                
                // 2. 이름 목록으로 제목 생성
                if participantNames.isEmpty {
                    thread.title = "알 수 없음"
                } else if participantNames.count == 1 {
                    // 1:1 채팅
                    thread.title = participantNames.first!
                } else {
                    // 그룹 채팅 (글자 수 기반 축약)
                    let maxTitleLength = 18
                    var currentTitle = ""
                    var namesAdded = 0
                    
                    for name in participantNames {
                        let separator = (namesAdded == 0) ? "" : ", "
                        let potentialTitle = currentTitle + separator + name
                        
                        if potentialTitle.count <= maxTitleLength {
                            currentTitle = potentialTitle
                            namesAdded += 1
                        } else {
                            if namesAdded == 0 {
                                currentTitle = name.prefix(maxTitleLength - 3) + "···"
                            } else {
                                currentTitle += ", ···"
                            }
                            break
                        }
                    }
                    thread.title = currentTitle
                }
                fetchedThreads[i] = thread
            }

            let newThreads = self.threads.filter { vmThread in
                !fetchedThreads.contains(where: { $0.id == vmThread.id })
            }
            
            let combinedThreads = fetchedThreads + newThreads
            
            self.threads = combinedThreads.sorted {
                ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast)
            }

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
            
            try await repo.markRead(threadId: threadId)
            
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
            let msg = try await repo.sendMessage(threadId: threadId, text: trimmed, cardID: nil)
            
            var arr = messagesByThread[threadId] ?? []
            arr.append(msg)
            messagesByThread[threadId] = arr
            
            if let idx = threads.firstIndex(where: { $0.id == threadId }) {
                var t = threads.remove(at: idx)
                t.lastMessageText = msg.text
                t.lastMessageCardTitle = nil
                t.lastMessageAt = msg.createdAt
                t.unreadCount = 0
                threads.insert(t, at: 0)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func sendCard(to threadId: String, card: Card) async {
        do {
            let msg = try await repo.sendMessage(threadId: threadId, text: nil, cardID: card.id)
            
            var arr = messagesByThread[threadId] ?? []
            arr.append(msg)
            messagesByThread[threadId] = arr
            
            if let idx = threads.firstIndex(where: { $0.id == threadId }) {
                var t = threads.remove(at: idx)
                t.lastMessageText = nil
                t.lastMessageCardTitle = card.title
                t.lastMessageAt = msg.createdAt
                t.unreadCount = 0
                threads.insert(t, at: 0)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func addNewThread(_ thread: ChatThread) async {
        if !threads.contains(where: { $0.id == thread.id }) {
            threads.insert(thread, at: 0)
            messagesByThread[thread.id] = []
            print("✅ 새 채팅방 추가: \(thread.title)")
        }
    }
    
    func leaveChat(threadId: String) async {
        do {
            try await repo.leaveChat(threadId: threadId)
            threads.removeAll { $0.id == threadId }
            messagesByThread.removeValue(forKey: threadId)
        } catch {
            self.errorMessage = "채팅방을 나가는 데 실패했습니다."
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
    
    // ✅ (추가) Card를 ID로 검색하는 헬퍼
    func getCard(byId id: UUID) -> Card? {
        return cardManager.allCards.first(where: { $0.id == id })
    }
}
