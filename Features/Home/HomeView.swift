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
                        Text("아직 카드가 없어요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("마이페이지 → 스크린샷에서 카드를 가져올 수 있어요.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 32)
                    Spacer().frame(height: S)
                }

                HomeSection(title: "⏳ Expiring Soon") {
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
                                .padding(.horizontal, 20)
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
                                .padding(.horizontal, 20)
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
                        .padding(.horizontal, 20)
                    }
                    Spacer().frame(height: S)
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
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
