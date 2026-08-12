import SwiftUI

/// 채팅 목록 화면 (상단의 "채팅" 탭 컨텐츠)
@MainActor
struct ShareChatListView: View {
    @ObservedObject var vm: ShareViewModel
    @Binding var selectedThread: ChatThread?
    @State private var showFriendSelection = false
    @State private var chatCreationError: String?

    var body: some View {
        ZStack {
            if vm.isLoading && vm.threads.isEmpty {
                ProgressView("채팅 목록을 불러오는 중...")
            } else if vm.threads.isEmpty {
                ContentUnavailableView {
                    Label("아직 채팅이 없어요", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text(vm.errorMessage ?? "아래 버튼을 눌러 친구와 대화를 시작해 보세요.")
                } actions: {
                    if vm.errorMessage != nil {
                        Button("다시 시도") {
                            Task { await vm.refreshThreads() }
                        }
                        .foregroundStyle(Color.pointBlue)
                    }
                }
            } else {
                List {
                    ForEach(vm.threads) { t in
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            
                            // 1:1 또는 그룹 아바타
                            // ✅ (수정) ShareComponents.swift의 뷰를 사용
                            ChatListAvatarView(vm: vm, thread: t)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // 첫 줄: 이름 + 시간
                                HStack(spacing: 0) {
                                    Text(t.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .lineLimit(1)
                                    Spacer()
                                    Text(vm.timeString(for: t.lastMessageAt))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // 둘째 줄: 메시지 + 안읽음표시
                                HStack(spacing: 0) {
                                    if let cardTitle = t.lastMessageCardTitle {
                                        Image(systemName: "doc.text.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .padding(.trailing, 4)
                                        Text(cardTitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    } else {
                                        Text(t.lastMessageText ?? "메시지가 없습니다")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // 안 읽음 배지
                                    if t.unreadCount > 0 {
                                        Text(t.unreadCount > 99 ? "99+" : "\(t.unreadCount)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .frame(minWidth: 24)
                                            .frame(height: 24)
                                            .background(Capsule().fill(Color.unreadBadgeRed))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        
                        // 구분선
                        if t.id != vm.threads.last?.id {
                            Divider()
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedThread = t
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(uiColor: .systemGroupedBackground))
                .refreshable { await vm.loadAll() }
            }
        }
        .sheet(isPresented: $showFriendSelection) {
            ShareFriendSelectionView(vm: vm) { selectedFriends in
                Task {
                    await startGroupChat(with: selectedFriends)
                }
            }
        }
        .alert("채팅방을 만들 수 없어요", isPresented: Binding(
            get: { chatCreationError != nil },
            set: { if !$0 { chatCreationError = nil } }
        )) {
            Button("확인", role: .cancel) { chatCreationError = nil }
        } message: {
            Text(chatCreationError ?? "")
        }
        // 탭바 위쪽 여백은 AppNavigation이 이미 확보해뒀으므로,
        // 이 버튼은 그 위에 바로 얹기만 하면 됩니다.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showFriendSelection = true
                } label: {
                    Image(systemName: "plus.bubble.fill")
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
            .padding(.bottom, CaplogTabBarMetrics.contentInset)
        }
    }
    
    /// 그룹 채팅 시작 (1:1 또는 단체 — 서버에 채팅방 생성 후 진입)
    private func startGroupChat(with friends: [Friend]) async {
        guard !friends.isEmpty else { return }
        
        let participantUserIds = friends.map { $0.id }
        let title: String
        if friends.count == 1 {
            title = friends[0].name
            if let existing = vm.threads.first(where: {
                ($0.participantIds.count == 2 && $0.participantIds.contains(friends[0].id))
                    || ($0.participantIds.isEmpty && $0.title == title)
            }) {
                selectedThread = existing
                return
            }
        } else {
            title = friends.map { $0.name }.sorted().joined(separator: ", ")
        }
        
        if let thread = await vm.createAndEnterChat(participantUserIds: participantUserIds, title: title) {
            selectedThread = thread
        } else {
            chatCreationError = vm.errorMessage ?? "네트워크 연결을 확인하고 다시 시도해 주세요."
        }
    }
}
