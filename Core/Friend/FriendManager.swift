import Foundation
import SwiftUI
import Combine

// MARK: - FriendManager (전역 친구 관리)

@MainActor
final class FriendManager: ObservableObject {
    
    // ✅ Mock 데이터 (개발용 - Friend로 통일)
    static let mockFriends: [Friend] = [
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
                friends = serverFriends  // 이미 Friend 타입이므로 그대로 사용
                print("✅ FriendManager: 서버에서 \(friends.count)명 친구 로드")
            } catch {
                print("⚠️ FriendManager: 친구 로드 실패 - \(error)")
                friends = []
            }
        }
    }
    
    /// 친구 추가
    func addFriend(name: String, profileImage: String = "avatar_default") {
        let newFriend = Friend(id: "temp_\(name)", name: name, avatarURL: nil, profileImage: profileImage)
        friends.append(newFriend)
        print("✅ FriendManager: 친구 추가됨 - \(name)")
    }
    
    /// 친구 삭제
    func removeFriend(id: String) {
        friends.removeAll { $0.id == id }
        print("✅ FriendManager: 친구 삭제됨")
    }
}
