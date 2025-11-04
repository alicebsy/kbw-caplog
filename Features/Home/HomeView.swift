import SwiftUI

struct HomeView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = HomeViewModel()

    @State private var selectedContent: Content? = nil
    @State private var shareTarget: Content? = nil
    @State private var fullscreenImage: String? = nil
    @State private var editingContent: Content? = nil
    @State private var selectedTab: CaplogTab = .home

    // 탭 이동용 상태
    @State private var showFolder = false
    @State private var showSearch = false
    @State private var showShare  = false
    @State private var showMyPage = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {

                    // Header
                    HomeHeader(
                        userName: vm.userName,
                        onTapNotification: { vm.showNotificationView = true }
                    )

                    // ✅ "Today's Summary" - 통일된 스타일로 변경
                    HomeSectionHeader(title: "Today's Summary")
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Coupon (green)
                    ExpiringCouponCard(
                        title: vm.coupon.title,
                        date: vm.coupon.expireDate,
                        brand: vm.coupon.brand
                    ) {
                        if let name = vm.coupon.screenshotName {
                            fullscreenImage = name
                        }
                    }
                    .padding(.horizontal, 20)

                    // Recommended
                    VStack(alignment: .leading, spacing: 0) {
                        HomeSectionHeader(title: "Recommended Contents")
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                            .padding(.bottom, -20)

                        TabView {
                            ForEach(vm.recommended.prefix(3)) { content in
                                HomeCardRow(
                                    content: content,
                                    onTap: { selectedContent = content },
                                    onShare: { shareTarget = content },
                                    onTapMore: { editingContent = content },
                                    onTapThumb: {
                                        if let first = content.screenshots.first {
                                            fullscreenImage = first
                                        } else {
                                            fullscreenImage = content.thumbnail
                                        }
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .frame(height: 250)
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                    }

                    // Recently Viewed
                    HomeSectionHeader(title: "Recently Viewed")
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        ForEach(vm.recommended.prefix(3)) { content in
                            RecentlyRow(
                                title: content.name,
                                meta: content.address,
                                thumb: content.thumbnail,
                                onTapCenter: { selectedContent = content },
                                onTapShare: { shareTarget = content },
                                onTapMore:  { editingContent = content },
                                onTapThumb: {
                                    if let first = content.screenshots.first {
                                        fullscreenImage = first
                                    } else {
                                        fullscreenImage = content.thumbnail
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
            }

            // 하단 탭
            CaplogTabBar(selected: selectedTab) { tab in
                selectedTab = tab
                onSelectTab?(tab)
                route(from: .home, to: tab)
            }
            .frame(maxWidth: .infinity)
        }
        
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }

        // ShareSheet
        .sheet(item: $shareTarget) { target in
            ShareSheetView(
                target: target,
                friends: vm.friends
            ) { ids, msg in
                print("Home 공유 → 대상: \(ids), 메시지: \(msg)")
            }
            .presentationDetents([.height(350)])
        }

        // 편집 시트
        .sheet(item: $editingContent) { ct in
            ContentEditSheet(content: ct) { updated in
                print("업데이트: \(updated)")
            }
            .presentationDetents([.medium, .large])
        }

        // 전체 이미지
        .fullScreenCover(isPresented: Binding(
            get: { fullscreenImage != nil },
            set: { if !$0 { fullscreenImage = nil } }
        )) {
            if let name = fullscreenImage {
                HomeImagePopupView(imageName: name)
            }
        }

        // 상세 이동 – id를 String으로 맞춰 전달
        .navigationDestination(item: $selectedContent) { ct in
            HomeContentDetailView(id: ct.id.uuidString)
        }

        .navigationDestination(isPresented: $vm.showNotificationView) { NotificationView() }
        .navigationDestination(isPresented: $showMyPage) { MyPageView() }
        .navigationDestination(isPresented: $showFolder) { FolderView() }
        .navigationDestination(isPresented: $showSearch) { SearchView() }
        .navigationDestination(isPresented: $showShare)  { ShareView() }
        
        // ✅ 화면 나타날 때마다 최신 데이터 로드
        .onAppear {
            Task {
                await vm.load()
            }
        }
        .task {
            await vm.load()
        }
    }

    // MARK: - 라우팅 함수
    private func route(from current: CaplogTab, to tab: CaplogTab) {
        guard current != tab else { return }
        switch tab {
        case .home:   break
        case .folder: showFolder = true
        case .search: showSearch = true
        case .share:  showShare  = true
        case .myPage: showMyPage = true
        }
    }
}
