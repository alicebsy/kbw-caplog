import SwiftUI
import Combine

@MainActor
struct ShareFriendListView: View {
    @ObservedObject var vm: ShareViewModel
    @Binding var selectedThread: ChatThread?
    @State private var showAdd = false
    @State private var friendToDelete: Friend?
    @State private var showDeleteConfirm = false
    @State private var chatOpenError: String?
    @State private var deletingFriendID: String?
    @State private var friendDeleteError: String?

    var body: some View {
        ZStack {
            if vm.isFriendsLoading && vm.friends.isEmpty {
                ProgressView("친구 목록을 불러오는 중...")
            } else if vm.friends.isEmpty {
                ContentUnavailableView {
                    Label("아직 친구가 없어요", systemImage: "person.2")
                } description: {
                    Text(vm.friendErrorMessage ?? "아래 버튼을 눌러 친구 ID로 추가해 보세요.")
                } actions: {
                    if vm.friendErrorMessage != nil {
                        Button("다시 시도") {
                            Task { await vm.reloadFriends() }
                        }
                        .foregroundStyle(Color.pointBlue)
                    }
                }
            } else {
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
                                // 채팅 버튼 → 대화창으로 이동
                                Button {
                                    Task {
                                        await startChat(with: friend)
                                    }
                                } label: {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.pointBlue)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                
                                // 삭제 버튼 (심플한 아이콘)
                                Button {
                                    friendToDelete = friend
                                    showDeleteConfirm = true
                                } label: {
                                    Group {
                                        if deletingFriendID == friend.id {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "trash")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundColor(Color.pointCoral)
                                        }
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .disabled(deletingFriendID != nil)
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
                .alert("채팅을 열 수 없어요", isPresented: Binding(
                    get: { chatOpenError != nil },
                    set: { if !$0 { chatOpenError = nil } }
                )) {
                    Button("확인", role: .cancel) { chatOpenError = nil }
                } message: {
                    Text(chatOpenError ?? "")
                }
            }
        }
        .alert("친구 삭제 실패", isPresented: Binding(
            get: { friendDeleteError != nil },
            set: { if !$0 { friendDeleteError = nil } }
        )) {
            Button("확인", role: .cancel) { friendDeleteError = nil }
        } message: {
            Text(friendDeleteError ?? "")
        }
        .sheet(isPresented: $showAdd) {
            // 친구 추가 시트
            ShareFriendSearchSheet(vm: vm)
        }
        // 하단 탭바와 겹치지 않도록 safeAreaInset + 탭바 높이만큼 여백
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
            }
            .padding(.top, 8)
            .padding(.bottom, 72) // 탭바(64) + 여유
        }
    }
    
    /// 개인 채팅 시작 (1:1) — 서버 스레드 목록 갱신 후 기존 방 우선, 없으면 생성
    private func startChat(with friend: Friend) async {
        await vm.refreshThreads()
        if let existing = vm.threads.first(where: {
            ($0.participantIds.count == 2 && $0.participantIds.contains(friend.id))
                || ($0.participantIds.isEmpty && $0.title == friend.name)
        }) {
            await MainActor.run {
                selectedThread = existing
            }
            return
        }
        if let serverThread = await vm.createAndEnterChat(participantUserIds: [friend.id], title: friend.name) {
            await MainActor.run {
                selectedThread = serverThread
            }
            return
        }
        let msg = vm.errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = (msg == nil || msg?.isEmpty == true)
            ? "서버에 연결할 수 없거나 채팅방을 만들 수 없어요. 백엔드가 켜져 있는지 확인해 주세요."
            : msg!
        await MainActor.run {
            chatOpenError = fallback
        }
        print("❌ createAndEnterChat 실패 – \(fallback)")
    }
    
    /// 친구 삭제
    private func deleteFriend(_ friend: Friend) {
        deletingFriendID = friend.id
        Task {
            let removed = await vm.removeFriend(id: friend.id)
            deletingFriendID = nil
            if removed {
                print("🗑️ \(friend.name)님 삭제 완료")
            } else {
                friendDeleteError = vm.friendErrorMessage ?? "친구를 삭제하지 못했습니다."
            }
        }
    }
}
