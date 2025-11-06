import SwiftUI

struct HomeView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = HomeViewModel()

    @State private var selectedCard: Card? = nil
    @State private var shareTarget: Card? = nil
    @State private var fullscreenImage: String? = nil
    @State private var editingCard: Card? = nil
    @State private var selectedTab: CaplogTab = .home

    // 하단 탭 라우팅
    @State private var showFolder = false
    @State private var showSearch = false
    @State private var showShare  = false
    @State private var showMyPage = false

    // 메트릭
    private let S = HomeMetrics.sectionSpacing // 24pt
    private let couponH   = HomeMetrics.couponHeight
    private let rowH      = HomeMetrics.rowHeight

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ── 상단 인사 헤더 ──
                HomeHeader(
                    userName: vm.userName,
                    onTapNotification: { vm.showNotificationView = true }
                )
                Spacer().frame(height: S) // 24pt

                // ── 섹션 1: Today's Summary (쿠폰 캐러셀) ──
                if !vm.coupons.isEmpty {
                    HomeSection(title: "🗓️ Today's Summary") {
                        TabView {
                            ForEach(vm.coupons) { card in
                                UnifiedCardView(
                                    card: card,
                                    style: .coupon,
                                    onTap: { selectedCard = card },
                                    onShare: { shareTarget = card },
                                    onMore: { editingCard = card },
                                    onTapImage: {
                                        if let url = card.thumbnailURL ?? card.screenshotURLs.first {
                                            fullscreenImage = url
                                        }
                                        // ✅ 수정: 이미지 클릭 시에도 최근 본 항목으로 등록
                                        CardManager.shared.markCardAsViewed(card)
                                    }
                                )
                                .frame(height: couponH)
                                .padding(.horizontal, 20)
                            }
                        }
                        .frame(height: couponH)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                    Spacer().frame(height: S) // 24pt
                }

                // ── 섹션 2: Recommended Contents ──
                if !vm.recommended.isEmpty {
                    HomeSection(title: "💡 Recommended Contents") {
                        TabView {
                            ForEach(vm.recommended.prefix(3)) { card in
                                UnifiedCardView(
                                    card: card, style: .row,
                                    onTap: { selectedCard = card },
                                    onShare: { shareTarget = card },
                                    onMore: { editingCard = card },
                                    onTapImage: {
                                        fullscreenImage = card.screenshotURLs.first ?? card.thumbnailName
                                        // ✅ 수정: 이미지 클릭 시에도 최근 본 항목으로 등록
                                        CardManager.shared.markCardAsViewed(card)
                                    }
                                )
                                .frame(minHeight: rowH)
                                .padding(.horizontal, 20)
                            }
                        }
                        .frame(height: rowH)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                    Spacer().frame(height: S) // 24pt
                }

                // ── 섹션 3: Recently Viewed ──
                if !vm.recent.isEmpty {
                    HomeSection(title: "👀 Recently Viewed") {
                        VStack(spacing: 12) {
                            ForEach(vm.recent.prefix(3)) { card in
                                UnifiedCardView(
                                    card: card, style: .row,
                                    onTap: { selectedCard = card },
                                    onShare: { shareTarget = card },
                                    onMore: { editingCard = card },
                                    onTapImage: {
                                        fullscreenImage = card.screenshotURLs.first ?? card.thumbnailName
                                        // ✅ 수정: 이미지 클릭 시에도 최근 본 항목으로 등록
                                        CardManager.shared.markCardAsViewed(card)
                                    }
                                )
                                .frame(minHeight: rowH)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    Spacer().frame(height: S) // 24pt
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            CaplogTabBar(selected: selectedTab) { tab in
                selectedTab = tab
                onSelectTab?(tab)
                route(from: .home, to: tab)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
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

        // 공유 시트
        .sheet(item: $shareTarget) { target in
            ShareSheetView(target: target, friends: vm.friends) { _, _ in }
                .presentationDetents([.height(350)])
        }

        // 편집 시트
        .sheet(item: $editingCard) { card in
            CardEditSheet(card: card) { _ in }
                .presentationDetents([.medium, .large])
        }

        // 전체 이미지 보기
        .fullScreenCover(isPresented: Binding(
            get: { fullscreenImage != nil },
            set: { if !$0 { fullscreenImage = nil } }
        )) {
            if let name = fullscreenImage {
                HomeImagePopupView(imageName: name)
            }
        }

        // 네비게이션
        .navigationDestination(item: $selectedCard) { CardDetailView(card: $0) }
        .navigationDestination(isPresented: $vm.showNotificationView) { NotificationView() }
        .navigationDestination(isPresented: $showMyPage) { MyPageView() }
        .navigationDestination(isPresented: $showFolder) { FolderView() }
        .navigationDestination(isPresented: $showSearch) { SearchView() }
        .navigationDestination(isPresented: $showShare)  { ShareView() }

        .task { await vm.load() }
    }

    // MARK: - 탭 라우팅
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
