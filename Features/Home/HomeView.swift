import SwiftUI

/// 알림 화면으로 가기 위한 value (navigationDestination용)
private enum NotificationDestination: Hashable { case open }

struct HomeView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = HomeViewModel()
    @StateObject private var appNotificationCenter = AppNotificationCenter.shared
    @ObservedObject private var pipelineStatus = ScreenshotPipelineStatus.shared

    @State private var selectedCard: Card? = nil
    @State private var fullscreenImage: String? = nil
    @State private var editingCard: Card? = nil
    @State private var notificationDestination: NotificationDestination? = nil

    // 메트릭
    private let S = HomeMetrics.sectionSpacing // 24pt
    private let couponH   = HomeMetrics.couponHeight
    private let rowH      = HomeMetrics.rowHeight

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                HomeHeader(
                    userName: vm.userName,
                    unreadNotificationCount: appNotificationCenter.unreadCount,
                    onTapNotification: { notificationDestination = .open }
                )
                Spacer().frame(height: S)

                if vm.isLoading && vm.recommended.isEmpty && vm.recent.isEmpty && vm.coupons.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("카드를 불러오고 있어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 42)
                } else if let loadError = vm.loadError,
                          vm.recommended.isEmpty, vm.recent.isEmpty, vm.coupons.isEmpty {
                    // 서버에서 못 받아온 경우. "카드가 없는 것"과 반드시 구분해야
                    // 사용자가 자기 카드가 사라졌다고 오해하지 않습니다.
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.pointAmber)
                        Text("카드를 불러오지 못했어요")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(loadError)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            Task { await vm.retry() }
                        } label: {
                            HStack(spacing: 8) {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(vm.isLoading ? "다시 불러오는 중..." : "다시 시도")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 42)
                            .background(Color.myPageSectionGreen)
                            .clipShape(Capsule())
                        }
                        .disabled(vm.isLoading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    Spacer().frame(height: S)
                } else if vm.recommended.isEmpty && vm.recent.isEmpty && vm.coupons.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.pointTeal.opacity(0.78))
                        Text("아직 카드가 없어요")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("스크린샷을 가져오면 중요한 내용을 카드로 정리해드려요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            Task { await vm.importScreenshotsFromGallery() }
                        } label: {
                            HStack(spacing: 8) {
                                if vm.isImportingScreenshots {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "photo.badge.plus")
                                }
                                Text(vm.isImportingScreenshots ? "카드 만드는 중..." : "스크린샷 가져오기")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 42)
                            .background(Color.myPageSectionGreen)
                            .clipShape(Capsule())
                        }
                        .disabled(vm.isImportingScreenshots)
                        if pipelineStatus.lastUpdated != nil {
                            Text(pipelineStatus.lastMessage)
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    pipelineStatus.phase == .failure ? Color.red : Color.secondary
                                )
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    Spacer().frame(height: S)
                }

                if vm.loadError != nil,
                   !(vm.recommended.isEmpty && vm.recent.isEmpty && vm.coupons.isEmpty) {
                    // 저장된 카드는 그대로 보여주되, 최신 상태가 아니라는 점을 알립니다.
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.pointAmber)
                        // .secondary는 흰 배경 기준 색이라 앰버 틴트 위에서는
                        // 3.16:1까지 떨어집니다. 반드시 읽어야 하는 경고이므로 본문 색을 씁니다.
                        Text("최신 카드를 불러오지 못해 저장된 내용을 보여주고 있어요.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.brandTextMain)
                        Spacer(minLength: 8)
                        Button("다시 시도") {
                            Task { await vm.retry() }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        // 색을 지정하지 않으면 iOS 기본 액센트(파란색)를 받아
                        // 앱의 딥그린 체계에서 혼자 튀고 대비도 3.25:1로 미달입니다.
                        .foregroundStyle(Color.homeGreenTint)
                        .disabled(vm.isLoading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pointAmber.opacity(0.10))
                    )
                    .padding(.horizontal, 20)
                    Spacer().frame(height: S)
                }

                HomeSection(
                    title: "마감 임박",
                    wrapInCard: false,
                    systemImage: "clock.badge.exclamationmark",
                    tint: .pointAmber
                ) {
                    if vm.coupons.isEmpty {
                        Text("마감일이 가까운 카드가 없어요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: couponH)
                            .padding(.horizontal, 20)
                    } else {
                        TabView {
                            ForEach(vm.coupons) { card in
                                UnifiedCardView(
                                    card: card,
                                    style: .coupon,
                                    onTap: { selectedCard = card },
                                    onMore: { editingCard = card },
                                    onTapImage: {
                                        if let url = card.thumbnailURL ?? card.screenshotURLs.first {
                                            fullscreenImage = url
                                        }
                                        CardManager.shared.markCardAsViewed(card)
                                    },
                                    isHomeScreen: true
                                )
                                .frame(height: couponH)
                                .padding(.horizontal, 16)
                                .id("\(card.id)-\(card.updatedAt.timeIntervalSince1970)")
                            }
                        }
                        .frame(height: couponH)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
                Spacer().frame(height: S)

                if !vm.recommended.isEmpty {
                    HomeSection(
                        title: vm.recommendationTitle,
                        systemImage: vm.recommendationTitle == "내 주변 추천" ? "location.fill" : "sparkles",
                        tint: .pointTeal
                    ) {
                        TabView {
                            ForEach(vm.recommended.prefix(3)) { card in
                                UnifiedCardView(
                                    card: card, style: .row,
                                    onTap: { selectedCard = card },
                                    onMore: { editingCard = card },
                                    onTapImage: {
                                        fullscreenImage = card.screenshotURLs.first ?? card.thumbnailName
                                        CardManager.shared.markCardAsViewed(card)
                                    }
                                )
                                .id("\(card.id)-\(card.updatedAt.timeIntervalSince1970)")
                                .padding(.horizontal, 4)
                            }
                        }
                        .frame(height: 180)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                    Spacer().frame(height: S)
                }

                if !vm.recent.isEmpty {
                    HomeSection(
                        title: "최근 본 카드",
                        systemImage: "clock.arrow.circlepath",
                        tint: .pointTeal
                    ) {
                        VStack(spacing: 12) {
                            ForEach(vm.recent.prefix(3)) { card in
                                UnifiedCardView(
                                    card: card, style: .row,
                                    onTap: { selectedCard = card },
                                    onMore: { editingCard = card },
                                    onTapImage: {
                                        fullscreenImage = card.screenshotURLs.first ?? card.thumbnailName
                                        CardManager.shared.markCardAsViewed(card)
                                    }
                                )
                                .frame(minHeight: rowH)
                                .id("\(card.id)-\(card.updatedAt.timeIntervalSince1970)")
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    Spacer().frame(height: S)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // 하단 탭바(커스텀) 높이만큼 여백을 줘서 콘텐츠가 가리지 않도록
            Color.clear
                .frame(height: 76)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("홈")
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

        // ✅ 편집 시트
        .sheet(item: $editingCard) { card in
            CardEditSheet(card: card) {
                // 카드 저장 후 홈 화면 데이터 갱신
                Task {
                    await vm.reloadHomeContent()
                }
            }
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

        // 네비게이션 (value 기반으로 알림 화면 진입 보장)
        .navigationDestination(item: $selectedCard) { CardDetailView(card: $0) }
        .navigationDestination(item: $notificationDestination) { _ in NotificationView() }

        .task {
            await vm.load()
            await appNotificationCenter.refresh()
        }
        .refreshable {
            await vm.load()
            await appNotificationCenter.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .homeTabSelected)) { _ in
            Task { await vm.reloadHomeContent() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await vm.reloadHomeContent()
                await vm.refreshNearbyRecommendations()
                await appNotificationCenter.refresh()
            }
        }
    }
}
