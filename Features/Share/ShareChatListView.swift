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
                // 불러오기 실패와 채팅이 없는 것은 다릅니다. 예전에는 실패해도
                // 제목이 "아직 채팅이 없어요"로 떠서, 설명과 서로 어긋났습니다.
                if let error = vm.errorMessage {
                    ContentUnavailableView {
                        Label("채팅 목록을 불러오지 못했어요", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("다시 시도") {
                            Task { await vm.refreshThreads() }
                        }
                        .foregroundStyle(Color.pointBlue)
                    }
                } else {
                    ContentUnavailableView {
                        Label("아직 채팅이 없어요", systemImage: "bubble.left.and.bubble.right")
                    } description: {
                        Text("아래 버튼을 눌러 친구와 대화를 시작해 보세요.")
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
                                        // .secondary는 흰 면에서 3.26:1이라 AA(4.5:1)에 못 미칩니다.
                                        .foregroundStyle(Color.brandTextSub)
                                }

                                // 둘째 줄: 메시지 + 안읽음표시
                                HStack(spacing: 0) {
                                    if let cardTitle = t.lastMessageCardTitle {
                                        Image(systemName: "doc.text.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.brandTextSub)
                                            .padding(.trailing, 4)
                                        Text(cardTitle)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.brandTextSub)
                                            .lineLimit(1)
                                    } else {
                                        Text(t.lastMessageText ?? "메시지가 없습니다")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.brandTextSub)
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
        // NavigationStack은 바깥 safeAreaInset을 자기 콘텐츠까지 전달하지 않습니다.
        // 그래서 이 버튼은 탭바 높이만큼 직접 띄워야 가려지지 않습니다.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Spacer()
                Button {
                    showFriendSelection = true
                } label: {
                    Image(systemName: "plus.bubble.fill")
                        .accessibilityLabel("새 대화 시작")
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
            // 방 제목으로 기존 방을 찾으면, 친구 이름으로 지어둔 단체방이
            // 1:1 대화 대신 열릴 수 있습니다. 참가자로만 판단합니다.
            if let existing = vm.threads.first(where: {
                $0.participantIds.count == 2 && $0.participantIds.contains(friends[0].id)
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
