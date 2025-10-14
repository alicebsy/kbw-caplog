import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    @State private var selectedContent: Content? = nil
    @State private var shareTarget: Content? = nil
    @State private var fullscreenImage: String? = nil
    @State private var editingContent: Content? = nil
    @State private var selectedTab: CaplogTab = .home

    // ✅ 탭 이동용 상태
    @State private var showFolder = false
    @State private var showSearch = false
    @State private var showShare  = false
    @State private var showMyPage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Header
                        HomeHeader(
                            userName: vm.userName,
                            onTapNotification: { vm.showNotificationView = true },
                            onTapProfile: { showMyPage = true }
                        )

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
                                .padding(.horizontal, 20)
                                .padding(.bottom, -8)

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

                // ✅ TabBar
                CaplogTabBar(selected: selectedTab) { tab in
                    selectedTab = tab
                    route(from: .home, to: tab)
                }
                .frame(maxWidth: .infinity)
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

            // 네비게이션 목적지
            .navigationDestination(item: $selectedContent) { ct in
                HomeContentDetailView(content: ct)
            }
            .navigationDestination(isPresented: $vm.showNotificationView) { NotificationView() }
            .navigationDestination(isPresented: $showMyPage) { MyPageView() }
            .navigationDestination(isPresented: $showFolder) { FolderView() }
            .navigationDestination(isPresented: $showSearch) {
                SearchView { tab in route(from: .search, to: tab) }
            }
            .navigationDestination(isPresented: $showShare)  {
                ShareView { tab in route(from: .share, to: tab) }
            }
        }
        .task { await vm.load() }
    }

    // MARK: - 라우팅
    private func route(from current: CaplogTab, to tab: CaplogTab) {
        guard current != tab else { return }
        switch tab {
        case .home:   break // 이미 Home
        case .folder: showFolder = true
        case .search: showSearch = true
        case .share:  showShare  = true
        case .mypage: showMyPage = true
        }
    }
}
