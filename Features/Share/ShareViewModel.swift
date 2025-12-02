import Foundation
import SwiftUI
import Combine

// MARK: - ChatMessage / ChatThread

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let senderId: String
    let createdAt: Date
    let text: String?
    let cardID: UUID?

    init(id: String = UUID().uuidString,
         senderId: String,
         text: String?,
         cardID: UUID?,
         createdAt: Date = Date()) {
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


// MARK: - Repository Protocol

protocol ShareRepository {
    func fetchFriends() async throws -> [Friend]
    func fetchChatThreads() async throws -> [ChatThread]
    func fetchMessages(threadId: String) async throws -> [ChatMessage]
    func sendMessage(threadId: String, text: String?, cardID: UUID?) async throws -> ChatMessage
    func markRead(threadId: String) async throws
    func leaveChat(threadId: String) async throws
}

extension ShareRepository {
    func markRead(threadId: String) async throws { }
    func leaveChat(threadId: String) async throws { }
}



// MARK: - MockShareRepository (전체)

final class MockShareRepository: ShareRepository {

    static let shared = MockShareRepository()

    // FriendManager.mockFriends ID 미리 가져오기
    private static let minhaID   = FriendManager.mockFriends.first(where: { $0.name == "우민하" })!.id
    private static let dahyeID   = FriendManager.mockFriends.first(where: { $0.name == "강다혜" })!.id
    private static let seoyeonID = FriendManager.mockFriends.first(where: { $0.name == "배서연" })!.id
    private static let ewhaID    = FriendManager.mockFriends.first(where: { $0.name == "김이화" })!.id
    private static let actorID   = FriendManager.mockFriends.first(where: { $0.name == "김배우" })!.id
    private static let junghoonID = FriendManager.mockFriends.first(where: { $0.name == "이정훈" })!.id
    private static let jiaID     = FriendManager.mockFriends.first(where: { $0.name == "송지아" })!.id
    private static let sujinID   = FriendManager.mockFriends.first(where: { $0.name == "박수진" })!.id
    private static let yurimID   = FriendManager.mockFriends.first(where: { $0.name == "신유림" })!.id
    private static let chaewonID = FriendManager.mockFriends.first(where: { $0.name == "임채원" })!.id
    private static let hayoonID  = FriendManager.mockFriends.first(where: { $0.name == "정하윤" })!.id
    private static let junyoungID = FriendManager.mockFriends.first(where: { $0.name == "최준영" })!.id
    private static let jiwooID   = FriendManager.mockFriends.first(where: { $0.name == "한지우" })!.id
    private static let inseongID = FriendManager.mockFriends.first(where: { $0.name == "황인성" })!.id
    private static let hongjieunID = FriendManager.mockFriends.first(where: { $0.name == "홍지은" })!.id

    private var _threads: [ChatThread] = []
    private var messageStore: [String: [ChatMessage]] = [:]



    // MARK: - init() 전체 코드 (메시지 + 스레드 전체 포함)
    private init() {

        // ---------------------------------------
        // 1. messageStore 전체 (네 mock 유지)
        // ---------------------------------------

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
            .init(senderId: Self.ewhaID, text: "아 여기! 나도 가봤어. 사케동 인정", cardID: nil, createdAt: Date().addingTimeInterval(-60*38))
        ]

        let t5Messages: [ChatMessage] = [
            .init(senderId: Self.minhaID, text: nil, cardID: MockCardIDs.nangman, createdAt: Date().addingTimeInterval(-60*15)),
            .init(senderId: Self.minhaID, text: "여기서 밥 먹자!", cardID: nil, createdAt: Date().addingTimeInterval(-60*14)),
            .init(senderId: Self.seoyeonID, text: "오 대박 여기 맛있어", cardID: nil, createdAt: Date().addingTimeInterval(-60*13)),
            .init(senderId: Self.dahyeID, text: "좋아! 맛있겠다", cardID: nil, createdAt: Date().addingTimeInterval(-60*12)),
            .init(senderId: "me", text: nil, cardID: MockCardIDs.starbucksCoupon, createdAt: Date().addingTimeInterval(-60*11)),
            .init(senderId: "me", text: "나 무료 쿠폰 있으니까 스타벅스 가서 커피도 마시자", cardID: nil, createdAt: Date().addingTimeInterval(-60*10)),
            .init(senderId: Self.ewhaID, text: "스타벅스 좋아", cardID: nil, createdAt: Date().addingTimeInterval(-60*9)),
            .init(senderId: Self.minhaID, text: "완벽한 계획이다 ㅋㅋ", cardID: nil, createdAt: Date().addingTimeInterval(-60*8))
        ]

        let t6Messages: [ChatMessage] = {
            var msgs: [ChatMessage] = []
            msgs.append(.init(senderId: Self.actorID, text: "다음 회의 장소 정했습니다.", cardID: nil, createdAt: Date().addingTimeInterval(-60*1000)))
            msgs.append(.init(senderId: Self.actorID, text: "여기서 하죠", cardID: MockCardIDs.cafeEround, createdAt: Date().addingTimeInterval(-60*999)))

            for i in 1...98 {
                msgs.append(.init(senderId: Self.junghoonID,
                                  text: "확인했습니다. \(i)",
                                  cardID: nil,
                                  createdAt: Date().addingTimeInterval(-60 * Double(900 - i))))
            }

            msgs.append(.init(senderId: Self.minhaID,
                              text: "네 저도 봤습니다.",
                              cardID: nil,
                              createdAt: Date().addingTimeInterval(-60 * 15)))

            return msgs
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
            .init(senderId: "me", text: "메가커피 쿠폰 있는데 커피 마시러 갈까?", cardID: MockCardIDs.megacoffeeCoupon, createdAt: Date().addingTimeInterval(-60*46)),
            .init(senderId: Self.minhaID, text: "와 미쳤다", cardID: nil, createdAt: Date().addingTimeInterval(-60*45)),
            .init(senderId: Self.chaewonID, text: "콜콜콜", cardID: nil, createdAt: Date().addingTimeInterval(-60*44)),
            .init(senderId: Self.hayoonID, text: "저 지금 집 가요", cardID: nil, createdAt: Date().addingTimeInterval(-60*43)),
            .init(senderId: "me", text: "오케이 3시에 메가커피 앞에서 보자", cardID: nil, createdAt: Date().addingTimeInterval(-60*42))
        ]

        let t10Messages: [ChatMessage] = [
            .init(senderId: Self.dahyeID, text: nil, cardID: MockCardIDs.makguksu, createdAt: Date().addingTimeInterval(-60*56)),
            .init(senderId: Self.dahyeID, text: "속초 가면 여기 꼭 가", cardID: nil, createdAt: Date().addingTimeInterval(-60*55)),
            .init(senderId: Self.junyoungID, text: "오 저장", cardID: nil, createdAt: Date().addingTimeInterval(-60*54)),
            .init(senderId: Self.jiwooID, text: "와 맛있겠다", cardID: nil, createdAt: Date().addingTimeInterval(-60*53)),
            .init(senderId: "me", text: "나도 여기 저장함!", cardID: nil, createdAt: Date().addingTimeInterval(-60*52))
        ]

        // messageStore 저장
        self.messageStore = [
            "t1": t1Messages,
            "t2": t2Messages,
            "t3": t3Messages,
            "t4": t4Messages,
            "t5": t5Messages,
            "t6": t6Messages,
            "t7": t7Messages,
            "t8": t8Messages,
            "t9": t9Messages,
            "t10": t10Messages
        ]


        // ---------------------------------------
        // 2. Thread 정의 전체
        // ---------------------------------------

        let unreadCount: (String) -> Int = { id in
            self.messageStore[id, default: []]
                .filter { $0.senderId != "me" }
                .count
        }

        self._threads = [
            .init(id: "t1", title: "",
                  participantIds: ["me", Self.minhaID],
                  lastMessageText: t1Messages.last?.text,
                  lastMessageAt: t1Messages.last?.createdAt,
                  unreadCount: unreadCount("t1"),
                  lastMessageCardTitle: t1Messages.last?.cardID != nil ? "무료 음료 쿠폰" : nil),

            .init(id: "t2", title: "",
                  participantIds: ["me", Self.dahyeID],
                  lastMessageText: t2Messages.last?.text,
                  lastMessageAt: t2Messages.last?.createdAt,
                  unreadCount: unreadCount("t2"),
                  lastMessageCardTitle: nil),

            .init(id: "t3", title: "",
                  participantIds: ["me", Self.seoyeonID],
                  lastMessageText: t3Messages.last?.text,
                  lastMessageAt: t3Messages.last?.createdAt,
                  unreadCount: unreadCount("t3"),
                  lastMessageCardTitle: nil),

            .init(id: "t4", title: "",
                  participantIds: ["me", Self.ewhaID],
                  lastMessageText: t4Messages.last?.text,
                  lastMessageAt: t4Messages.last?.createdAt,
                  unreadCount: unreadCount("t4"),
                  lastMessageCardTitle: t4Messages.last?.cardID != nil ? "낭만식탁" : nil),

            .init(id: "t5", title: "",
                  participantIds: ["me", Self.dahyeID, Self.seoyeonID, Self.minhaID, Self.ewhaID],
                  lastMessageText: t5Messages.last?.text,
                  lastMessageAt: t5Messages.last?.createdAt,
                  unreadCount: unreadCount("t5"),
                  lastMessageCardTitle: nil),

            .init(id: "t6", title: "",
                  participantIds: ["me", Self.actorID, Self.junghoonID, Self.minhaID],
                  lastMessageText: t6Messages.last?.text,
                  lastMessageAt: t6Messages.last?.createdAt,
                  unreadCount: unreadCount("t6"),
                  lastMessageCardTitle: nil),

            .init(id: "t7", title: "",
                  participantIds: ["me", Self.dahyeID, Self.jiaID],
                  lastMessageText: t7Messages.last?.text,
                  lastMessageAt: t7Messages.last?.createdAt,
                  unreadCount: unreadCount("t7"),
                  lastMessageCardTitle: t7Messages.last?.cardID != nil ? "AI와 미래 전시회" : nil),

            .init(id: "t8", title: "",
                  participantIds: ["me", Self.seoyeonID, Self.sujinID],
                  lastMessageText: t8Messages.last?.text,
                  lastMessageAt: t8Messages.last?.createdAt,
                  unreadCount: unreadCount("t8"),
                  lastMessageCardTitle: t8Messages.last?.cardID != nil ? "낭만식탁" : nil),

            .init(id: "t9", title: "",
                  participantIds: ["me", Self.minhaID, Self.chaewonID, Self.hayoonID],
                  lastMessageText: t9Messages.last?.text,
                  lastMessageAt: t9Messages.last?.createdAt,
                  unreadCount: unreadCount("t9"),
                  lastMessageCardTitle: t9Messages.last?.cardID != nil ? "(ICE)아메리카노" : nil),

            .init(id: "t10", title: "",
                  participantIds: ["me", Self.dahyeID, Self.junyoungID, Self.jiwooID],
                  lastMessageText: t10Messages.last?.text,
                  lastMessageAt: t10Messages.last?.createdAt,
                  unreadCount: unreadCount("t10"),
                  lastMessageCardTitle: t10Messages.last?.cardID != nil ? "속초 막국수 맛집" : nil)
        ]
    }



    // MARK: - Repository Methods

    func fetchFriends() async throws -> [Friend] {
        try? await Task.sleep(nanoseconds: 100_000_000)

        return FriendManager.mockFriends
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

        let msg = ChatMessage(senderId: "me", text: text, cardID: cardID)
        messageStore[threadId, default: []].append(msg)

        if let idx = _threads.firstIndex(where: { $0.id == threadId }) {
            _threads[idx].lastMessageText = text
            _threads[idx].lastMessageAt = msg.createdAt
            _threads[idx].lastMessageCardTitle = nil
        }
        return msg
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
    
    // 싱글톤
    nonisolated static let shared = ShareViewModel()

    // Published
    @Published var friends: [Friend] = []
    @Published var threads: [ChatThread] = []
    @Published var messagesByThread: [String: [ChatMessage]] = [:]

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchKeyword: String = ""

    private var cancellables = Set<AnyCancellable>()

    // 저장소 (Mock or 실제 API)
    private nonisolated let repo: ShareRepository
    private nonisolated let cardManager = CardManager.shared


    // --------------------------------------------------
    // MARK: - init()
    // --------------------------------------------------
    private nonisolated init(repo: ShareRepository = MockShareRepository.shared) {
        self.repo = repo
        
        // 🔥 (4번 기능) 프로필 변경 감지 — nickname, profileImageName 모두 반영
        NotificationCenter.default.publisher(for: .userProfileUpdated)
            .sink { [weak self] noti in
                guard let self else { return }
                
                let newName  = noti.userInfo?["nickname"] as? String
                let newImage = noti.userInfo?["profileImageName"] as? String
                
                Task { @MainActor in
                    self.applyMyProfileUpdate(name: newName, imageName: newImage)
                }
            }
            .store(in: &cancellables)
    }


    // --------------------------------------------------
    // MARK: - 로딩 함수
    // --------------------------------------------------

    func loadAll() async {
        await loadFriends()
        await loadThreads()
    }

    private func loadFriends() async {
        do {
            var fs = try await repo.fetchFriends()

            // 가나다순 정렬
            fs.sort { $0.name.localizedCompare($1.name) == .orderedAscending }

            self.friends = fs
            print("✅ ShareViewModel: \(fs.count)명 친구 로드 완료")
        }
        catch {
            self.errorMessage = error.localizedDescription
        }
    }


    private func loadThreads() async {
        do {
            var list = try await repo.fetchChatThreads()

            // 참여자 목록으로 제목 생성
            for i in 0..<list.count {
                var t = list[i]

                // me 제외한 나머지 이름
                let names = t.participantIds
                    .compactMap { id -> String? in
                        guard id != "me" else { return nil }
                        return friends.first(where: { $0.id == id })?.name
                    }
                    .sorted()

                if names.isEmpty {
                    t.title = "알 수 없음"
                }
                else if names.count == 1 {
                    t.title = names.first!
                }
                else {
                    // 너무 길면 축약
                    let limit = 18
                    var result = ""
                    var added = 0
                    
                    for name in names {
                        let sep = added == 0 ? "" : ", "
                        let trial = result + sep + name
                        
                        if trial.count <= limit {
                            result = trial
                            added += 1
                        } else {
                            result += ", ···"
                            break
                        }
                    }
                    t.title = result
                }

                list[i] = t
            }

            // 정렬: 마지막 메시지 최신 순
            list.sort {
                ($0.lastMessageAt ?? .distantPast) >
                ($1.lastMessageAt ?? .distantPast)
            }

            self.threads = list
        }
        catch {
            self.errorMessage = error.localizedDescription
        }
    }


    // --------------------------------------------------
    // MARK: - 메시지 열기
    // --------------------------------------------------

    func openThread(_ threadId: String) async {
        do {
            let msgs = try await repo.fetchMessages(threadId: threadId)
            messagesByThread[threadId] = msgs

            // 읽음 처리
            try await repo.markRead(threadId: threadId)

            // thread unreadCount = 0
            if let idx = threads.firstIndex(where: { $0.id == threadId }) {
                var t = threads[idx]
                t.unreadCount = 0
                threads[idx] = t
            }
        }
        catch {
            self.errorMessage = error.localizedDescription
        }
    }


    // --------------------------------------------------
    // MARK: - 메시지 전송
    // --------------------------------------------------

    func send(to threadId: String, text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let newMsg = try await repo.sendMessage(
                threadId: threadId,
                text: trimmed,
                cardID: nil
            )

            messagesByThread[threadId, default: []].append(newMsg)

            // thread 업데이트 (맨 위로)
            if let idx = threads.firstIndex(where: { $0.id == threadId }) {
                var t = threads.remove(at: idx)
                t.lastMessageText = newMsg.text
                t.lastMessageCardTitle = nil
                t.lastMessageAt = newMsg.createdAt
                t.unreadCount = 0
                threads.insert(t, at: 0)
            }
        }
        catch {
            self.errorMessage = error.localizedDescription
        }
    }


    func sendCard(to threadId: String, card: Card) async {
        do {
            let newMsg = try await repo.sendMessage(
                threadId: threadId,
                text: nil,
                cardID: card.id
            )

            messagesByThread[threadId, default: []].append(newMsg)

            // 스레드 업데이트
            if let idx = threads.firstIndex(where: { $0.id == threadId }) {
                var t = threads.remove(at: idx)
                t.lastMessageText = nil
                t.lastMessageCardTitle = card.title
                t.lastMessageAt = newMsg.createdAt
                t.unreadCount = 0
                threads.insert(t, at: 0)
            }
        }
        catch {
            self.errorMessage = error.localizedDescription
        }
    }


    // --------------------------------------------------
    // MARK: - 새 채팅방
    // --------------------------------------------------

    func addNewThread(_ thread: ChatThread) async {
        if !threads.contains(where: { $0.id == thread.id }) {
            threads.insert(thread, at: 0)
            messagesByThread[thread.id] = []
            print("✅ 새 채팅방 추가: \(thread.title)")
        }
    }


    // --------------------------------------------------
    // MARK: - 채팅방 나가기
    // --------------------------------------------------

    func leaveChat(threadId: String) async {
        do {
            try await repo.leaveChat(threadId: threadId)
            threads.removeAll { $0.id == threadId }
            messagesByThread.removeValue(forKey: threadId)
        }
        catch {
            self.errorMessage = "채팅방을 나가는 데 실패했습니다."
        }
    }


    // --------------------------------------------------
    // MARK: - 기타
    // --------------------------------------------------

    var filteredFriends: [Friend] {
        guard !searchKeyword.isEmpty else { return friends }
        return friends.filter {
            $0.name.localizedCaseInsensitiveContains(searchKeyword)
        }
    }

    func timeString(for date: Date?) -> String {
        guard let date else { return "" }

        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")

        if Calendar.current.isDateInToday(date) {
            f.dateFormat = "a h:mm"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) {
            f.dateFormat = "M/d"
        } else {
            f.dateFormat = "yy/M/d"
        }
        return f.string(from: date)
    }


    // --------------------------------------------------
    // MARK: - 🔥 (4번) MyPage 프로필 업데이트 반영
    // --------------------------------------------------
    private func applyMyProfileUpdate(name: String?, imageName: String?) {
        print("📢 ShareViewModel: 프로필 업데이트 감지 — 모든 탭 반영 시작")

        // 1) 친구 목록에서 me 업데이트
        friends = friends.map { f in
            if f.id == "me" {
                return Friend(
                    id: f.id,
                    name: name ?? f.name,
                    avatarURL: f.avatarURL,
                    profileImage: imageName ?? f.profileImage
                )
            }
            return f
        }

        // 2) 채팅방 리스트에서 me 이름 반영
        threads = threads.map { thread in
            var t = thread
            if t.participantIds.contains("me"), let newName = name {
                // 단톡방이면 자동으로 연쇄적으로 반영됨
                t.title = t.title.replacingOccurrences(of: friends.first(where: { $0.id == "me" })?.name ?? "나",
                                                       with: newName)
            }
            return t
        }

        // 3) 메시지 목록에서 프로필 변경은 이름을 messageRow에서 자동 참조하므로 OK

        // 4) UI 다시 그림
        objectWillChange.send()

        print("✅ ShareViewModel: 프로필 업데이트 전체 반영 완료")
    }


    // 카드 데이터 접근
    func getCard(byId id: UUID) -> Card? {
        return cardManager.allCards.first(where: { $0.id == id })
    }
}
