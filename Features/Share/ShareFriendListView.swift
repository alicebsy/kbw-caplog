import SwiftUI
import Combine

@MainActor
struct ShareFriendListView: View {
    @ObservedObject var vm: ShareViewModel
    @Binding var selectedThread: ChatThread?
    @State private var showAdd = false
    @State private var friendToDelete: Friend?
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            List {
                ForEach(vm.friends) { friend in // vm.friends는 이미 가나다순 정렬됨
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            
                            // 왼쪽 여백 추가 (프로필 오른쪽으로 이동)
                            Spacer().frame(width: 4)
                            
                            // ✅ (수정) 공용 뷰 사용으로 로직 통일
                            ProfileAvatarView(
                                profileImage: friend.profileImage,
                                avatarURL: friend.avatarURL?.absoluteString
                            )
                            
                            // 이름
                            Text(friend.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            HStack(spacing: 26) {
                                // 채팅 버튼 (심플한 아이콘)
                                Button {
                                    Task {
                                        await startChat(with: friend)
                                    }
                                } label: {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.blue.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                                
                                // 삭제 버튼 (심플한 아이콘)
                                Button {
                                    friendToDelete = friend
                                    showDeleteConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(Color.registerRed.opacity(0.75))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // 오른쪽 여백 추가 (버튼 왼쪽으로 이동)
                            Spacer().frame(width: 4)
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
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .alert("친구 삭제", isPresented: $showDeleteConfirm, presenting: friendToDelete) { friend in
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    deleteFriend(friend)
                }
            } message: { friend in
                Text("\(friend.name)님을 친구 목록에서 삭제하시겠습니까?")
            }
        }
        .sheet(isPresented: $showAdd) {
            // 친구 추가 시트
            ShareFriendSearchSheet(vm: vm)
        }
        // 하단 탭바와 겹치지 않도록 safeAreaInset으로 버튼 배치
        .safeAreaInset(edge: .bottom, spacing: 0) {
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
                                .fill(Color.myPageSectionGreen)
                                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 12)
            }
            .padding(.top, 4)
        }
    }
    
    /// 개인 채팅 시작 (1:1 — 서버에 채팅방 생성 후 진입)
    private func startChat(with friend: Friend) async {
        // 기존 채팅방이 있으면 이동 (서버 목록 기준: 제목이 해당 친구 이름인 1:1 방)
        if let existingThread = vm.threads.first(where: { $0.title == friend.name && $0.participantIds.count <= 2 }) {
            selectedThread = existingThread
            return
        }
        // 서버에 1:1 채팅방 생성 후 진입
        if let thread = await vm.createAndEnterChat(participantUserIds: [friend.id], title: friend.name) {
            selectedThread = thread
        }
    }
    
    /// 친구 삭제
    private func deleteFriend(_ friend: Friend) {
        // ViewModel 쪽에서도 동기화
        vm.removeFriend(id: friend.id)
        print("🗑️ \(friend.name)님 삭제 완료")
    }
}
