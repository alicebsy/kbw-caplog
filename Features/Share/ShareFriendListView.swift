import SwiftUI
import Combine

@MainActor
struct ShareFriendListView: View {
    @ObservedObject var vm: ShareViewModel
    @State private var showAdd = false
    @State private var friendToDelete: Friend?
    @State private var showDeleteConfirm = false
    @State private var selectedThread: ChatThread?

    var body: some View {
        ZStack {
            List {
                ForEach(vm.friends) { friend in // vm.friends는 이미 가나다순 정렬됨
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            // 프로필 이미지
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            // 이름
                            Text(friend.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            // 채팅 버튼
                            Button {
                                Task {
                                    await startChat(with: friend)
                                }
                            } label: {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 40, height: 40)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            // 삭제 버튼
                            Button {
                                friendToDelete = friend
                                showDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 40, height: 40)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        
                        // 구분선 (완전히 왼쪽부터)
                        if friend.id != vm.friends.last?.id {
                            Divider()
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .alert("친구 삭제", isPresented: $showDeleteConfirm, presenting: friendToDelete) { friend in
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    deleteFriend(friend)
                }
            } message: { friend in
                Text("\(friend.name)님을 친구 목록에서 삭제하시겠습니까?")
            }
            .sheet(isPresented: $showAdd) {
                // ✅ (수정) ShareFriendSearchSheet에 vm을 전달
                ShareFriendSearchSheet(vm: vm)
            }
            .navigationDestination(item: $selectedThread) { thread in
                ChatRoomView(vm: vm, thread: thread)
            }
            
            // 플로팅 친구 추가 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    /// 개인 채팅 시작
    private func startChat(with friend: Friend) async {
        // 기존 채팅방 찾기 (1:1 채팅방)
        if let existingThread = vm.threads.first(where: { thread in
            thread.participantIds.count == 2 &&
            thread.participantIds.contains(friend.id) &&
            thread.participantIds.contains("me")
        }) {
            // 기존 채팅방으로 이동
            print("💬 기존 채팅방으로 이동: \(friend.name)")
            selectedThread = existingThread
        } else {
            // 새 채팅방 생성
            print("💬 \(friend.name)님과 새 채팅 시작")
            let newThread = ChatThread(
                id: "new_\(friend.id)_\(UUID().uuidString)",
                title: friend.name,
                participantIds: ["me", friend.id],
                lastMessageText: nil,
                lastMessageAt: Date(),
                unreadCount: 0
            )
            
            // ViewModel에 새 스레드 추가
            await vm.addNewThread(newThread)
            
            selectedThread = newThread
        }
    }
    
    /// 친구 삭제
    private func deleteFriend(_ friend: Friend) {
        // ✅ (수정) ID 타입을 String으로 변경
        FriendManager.shared.removeFriend(id: friend.id)
        print("🗑️ \(friend.name)님 삭제 완료")
    }
}
