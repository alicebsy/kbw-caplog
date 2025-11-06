import Foundation
import SwiftUI
import Combine

// MARK: - FriendManager (전역 친구 관리)

@MainActor
final class FriendManager: ObservableObject {
    // ✅ ShareFriend 모델 사용 (ShareSheetView와 호환)
    @Published private(set) var friends: [ShareFriend] = []
    
    private let shareAPI = ShareAPI()
    private let useMockData = true  // 개발 중에는 true
    
    // 싱글톤 패턴 (선택사항)
    static let shared = FriendManager()
    
    init() {
        // 초기화 시 로드
        Task {
            await loadFriends()
        }
    }
    
    /// 친구 목록 로드
    func loadFriends() async {
        if useMockData {
            // ✅ Mock 데이터 (아바타 이미지 있음)
            friends = [
                ShareFriend(id: UUID(), name: "다혜", avatar: "avatar1"),
                ShareFriend(id: UUID(), name: "서연", avatar: "avatar2"),
                ShareFriend(id: UUID(), name: "민하", avatar: "avatar3"),
                ShareFriend(id: UUID(), name: "바리", avatar: "avatar4")
            ]
            print("✅ FriendManager: Mock 친구 \(friends.count)명 로드")
        } else {
            // ✅ 실제 API 호출
            do {
                let serverFriends = try await shareAPI.fetchFriends()
                
                // Friend → ShareFriend 변환
                friends = serverFriends.map { friend in
                    ShareFriend(
                        id: UUID(),  // 새 UUID 생성
                        name: friend.name,
                        avatar: friend.avatarURL?.absoluteString ?? "avatar_default"
                    )
                }
                print("✅ FriendManager: 서버에서 \(friends.count)명 친구 로드")
            } catch {
                print("⚠️ FriendManager: 친구 로드 실패 - \(error)")
                // 에러 시 빈 배열 유지
                friends = []
            }
        }
    }
    
    /// 친구 추가
    func addFriend(name: String, avatar: String = "avatar_default") {
        let newFriend = ShareFriend(id: UUID(), name: name, avatar: avatar)
        friends.append(newFriend)
        print("✅ FriendManager: 친구 추가됨 - \(name)")
    }
    
    /// 친구 삭제
    func removeFriend(id: UUID) {
        friends.removeAll { $0.id == id }
        print("✅ FriendManager: 친구 삭제됨")
    }
}
