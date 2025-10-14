import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    @State private var selectedContent: Content? = nil
    @State private var shareTarget: Content? = nil
    @State private var fullscreenImage: String? = nil
    @State private var editingContent: Content? = nil
    @State private var selectedTab: CaplogTab = .home

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Header
                        HomeHeader(
                            userName: vm.userName,
                            onTapNotification: { vm.showNotificationView = true },
                            onTapProfile: { vm.showMyPageView = true }
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

                        // Recommended (헤더-카드 간격 강제 축소)
                        VStack(alignment: .leading, spacing: 0) {
                            HomeSectionHeader(title: "Recommended Contents")
                                .padding(.horizontal, 20)
                                .padding(.bottom, -8) // 헤더 내부 기본 하단 여백 상쇄

                            TabView {
                                ForEach(vm.recommended.prefix(3)) { content in
                                    HomeCardRow(
                                        content: content,
                                        onTap: { selectedContent = content },     // 가운데 탭 → 상세
                                        onShare: { shareTarget = content },       // 공유
                                        onTapMore: { editingContent = content },  // … → 상세정보 수정
                                        onTapThumb: {                              // 우측 이미지 → 전체보기
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
                                    onTapMore:  { editingContent = content }, // … → 상세정보 수정
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
                        .padding(.bottom, 80) // 탭바 공간
                    }
                }

                // TabBar
                CaplogTabBar(selected: selectedTab) { tab in
                    selectedTab = tab
                    switch tab {
                    case .search:
                        // TODO: 검색 화면 열기
                        break
                    case .folder:
                        // TODO: 보관함 화면 열기
                        break
                    case .home:
                        break
                    case .share:
                        // TODO: 공유 허브 열기
                        break
                    case .mypage:
                        vm.showMyPageView = true
                    }
                }
                .frame(maxWidth: CGFloat.infinity)

            }

            // 공유 시트
            .sheet(item: $shareTarget) { ct in
                HomeShareView(
                    target: ct,
                    friends: vm.friends
                ) { ids, msg in
                    print("공유 대상: \(ids), 메시지: \(msg)")
                }
                .presentationDetents([.height(350)])
            }

            // 편집 시트(상세정보 수정)
            .sheet(item: $editingContent) { ct in
                ContentEditSheet(content: ct) { updated in
                    // TODO: Spring API 호출
                    print("업데이트: \(updated)")
                }
                .presentationDetents([.medium, .large])
            }

            // 전체 이미지
            .fullScreenCover(
                isPresented: Binding(
                    get: { fullscreenImage != nil },
                    set: { if !$0 { fullscreenImage = nil } }
                )
            ) {
                if let name = fullscreenImage {
                    HomeImagePopupView(imageName: name)
                }
            }

            // 네비게이션
            .navigationDestination(item: $selectedContent) { ct in
                HomeContentDetailView(content: ct)
            }
            .navigationDestination(isPresented: $vm.showNotificationView) {
                NotificationView()
            }
            .navigationDestination(isPresented: $vm.showMyPageView) {
                MyPageView()
            }
        }
        .task { await vm.load() }
    }
}
