import Foundation
import SwiftUI
import Combine

// MARK: - FriendManager (전역 친구 관리)

@MainActor
final class FriendManager: ObservableObject {
    
    // ✅ Mock 데이터 (개발용 - ShareFriend는 유지)
    static let mockFriends: [ShareFriend] = [
        ShareFriend(id: "2276003", name: "강다혜", avatar: "avatar1"),
        ShareFriend(id: "alicebsy", name: "배서연", avatar: "avatar3"),
        ShareFriend(id: "minha2469", name: "우민하", avatar: "avatar2"),
        ShareFriend(id: "kimewha1886", name: "김이화", avatar: "avatar_default"),
        ShareFriend(id: "actor_kim", name: "김배우", avatar: "avatar_default"),
        ShareFriend(id: "sujin_park", name: "박수진", avatar: "avatar_default"),
        ShareFriend(id: "jia_song", name: "송지아", avatar: "avatar_default"),
        ShareFriend(id: "yurim_shin", name: "신유림", avatar: "avatar_default"),
        ShareFriend(id: "jieunhong", name: "홍지은", avatar: "avatar_default"),
        ShareFriend(id: "junghoon_lee", name: "이정훈", avatar: "avatar_default"),
        ShareFriend(id: "chaewon_lim", name: "임채원", avatar: "avatar_default"),
        ShareFriend(id: "hayoon_jung", name: "정하윤", avatar: "avatar_default"),
        ShareFriend(id: "junyoung_choi", name: "최준영", avatar: "avatar_default"),
        ShareFriend(id: "jiwoo_han", name: "한지우", avatar: "avatar_default"),
        ShareFriend(id: "inseong_hwang", name: "황인성", avatar: "avatar_default")
    ]
    
    @Published private(set) var friends: [ShareFriend] = []
    
    private let shareAPI = ShareAPI()
    private let useMockData = true  // 개발 중에는 true
    
    static let shared = FriendManager()
    
    init() {
        Task {
            await loadFriends()
        }
    }
    
    /// 친구 목록 로드
    func loadFriends() async {
        if useMockData {
            friends = Self.mockFriends
            print("✅ FriendManager: Mock 친구 \(friends.count)명 로드")
        } else {
            // 실제 API 호출
            do {
                let serverFriends = try await shareAPI.fetchFriends()
                friends = serverFriends.map { friend in
                    ShareFriend(
                        id: friend.id,
                        name: friend.name,
                        avatar: friend.avatarURL?.absoluteString ?? "avatar_default"
                    )
                }
                print("✅ FriendManager: 서버에서 \(friends.count)명 친구 로드")
            } catch {
                print("⚠️ FriendManager: 친구 로드 실패 - \(error)")
                friends = []
            }
        }
    }
    
    /// ✅ ShareFriend → Friend 변환 헬퍼 (profileImage 포함)
    static func toFriend(_ shareFriend: ShareFriend) -> Friend {
        // ✅ avatar 값이 있으면 profileImage로 전달 ("avatar_default"도 포함)
        let profileImage: String? = shareFriend.avatar.isEmpty ? nil : shareFriend.avatar
        
        return Friend(
            id: shareFriend.id,
            name: shareFriend.name,
            avatarURL: nil,
            profileImage: profileImage
        )
    }
    
    /// 친구 추가
    func addFriend(name: String, avatar: String = "avatar_default") {
        let newFriend = ShareFriend(id: "temp_\(name)", name: name, avatar: avatar)
        friends.append(newFriend)
        print("✅ FriendManager: 친구 추가됨 - \(name)")
    }
    
    /// 친구 삭제
    func removeFriend(id: String) {
        friends.removeAll { $0.id == id }
        print("✅ FriendManager: 친구 삭제됨")
    }
}
