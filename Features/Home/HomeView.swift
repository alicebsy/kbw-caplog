import SwiftUI

/// 알림 화면으로 가기 위한 value (navigationDestination용)
private enum NotificationDestination: Hashable { case open }

struct HomeView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = HomeViewModel()

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
                    onTapNotification: { notificationDestination = .open }
                )
                Spacer().frame(height: S)

                if vm.recommended.isEmpty && vm.recent.isEmpty && vm.coupons.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.myPageSectionGreen.opacity(0.6))
                        Text("아직 카드가 없어요")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("마이페이지에서 스크린샷을 가져와 보세요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
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

                HomeSection(title: "⏳ Expiring Soon", wrapInCard: false) {
                    if vm.coupons.isEmpty {
                        Text("마감 임박한 스크린샷이 아직 없어요")
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
                    HomeSection(title: "💡 Recommended Contents") {
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
                    HomeSection(title: "👀 Recently Viewed") {
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

        .task { await vm.load() }
        .refreshable { await vm.load() }
        .onReceive(NotificationCenter.default.publisher(for: .homeTabSelected)) { _ in
            Task { await vm.reloadHomeContent() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await vm.reloadHomeContent() }
        }
    }
}
