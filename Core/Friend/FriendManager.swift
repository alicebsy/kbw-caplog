import Foundation
import SwiftUI
import Combine

// MARK: - FriendManager (전역 친구 관리)

@MainActor
final class FriendManager: ObservableObject {
    
    // Preview와 명시적인 Mock 저장소에서만 사용하는 샘플 데이터
    nonisolated static let mockFriends: [Friend] = [
        Friend(id: "2276003", name: "강다혜", avatarURL: nil, profileImage: "avatar1"),
        Friend(id: "alicebsy", name: "배서연", avatarURL: nil, profileImage: "avatar3"),
        Friend(id: "minha2469", name: "우민하", avatarURL: nil, profileImage: "avatar2"),
        Friend(id: "kimewha1886", name: "김이화", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "actor_kim", name: "김배우", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "sujin_park", name: "박수진", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "jia_song", name: "송지아", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "yurim_shin", name: "신유림", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "jieunhong", name: "홍지은", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "junghoon_lee", name: "이정훈", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "chaewon_lim", name: "임채원", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "hayoon_jung", name: "정하윤", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "junyoung_choi", name: "최준영", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "jiwoo_han", name: "한지우", avatarURL: nil, profileImage: "avatar_default"),
        Friend(id: "inseong_hwang", name: "황인성", avatarURL: nil, profileImage: "avatar_default")
    ]
    
    @Published private(set) var friends: [Friend] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let friendAPI = FriendAPI()
    
    static let shared = FriendManager()
    
    init() {
        Task {
            await loadFriends()
        }
    }
    
    /// 친구 목록 로드
    func loadFriends() async {
        isLoading = true
        defer { isLoading = false }
        do {
            friends = try await friendAPI.list().sorted {
                $0.name.localizedCompare($1.name) == .orderedAscending
            }
            errorMessage = nil
            print("✅ FriendManager: 서버에서 \(friends.count)명 친구 로드")
        } catch {
            errorMessage = error.localizedDescription
            friends = []
            print("⚠️ FriendManager: 친구 로드 실패 - \(error)")
        }
    }
    
    func applyAddedFriend(_ friend: Friend) {
        friends.removeAll { $0.id == friend.id }
        friends.append(friend)
        friends.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    func applyRemovedFriend(id: String) {
        friends.removeAll { $0.id == id }
    }
}
