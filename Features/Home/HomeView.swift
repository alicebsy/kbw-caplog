import SwiftUI

struct HomeView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = HomeViewModel()
    @ObservedObject private var pipelineStatus = ScreenshotPipelineStatus.shared

    @State private var selectedCard: Card? = nil
    @State private var fullscreenImage: String? = nil
    @State private var editingCard: Card? = nil

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

                // ── 카드 없을 때: 스크린샷에서 카드 가져오기 안내 ──
                if vm.recommended.isEmpty && vm.recent.isEmpty && vm.coupons.isEmpty {
                    VStack(spacing: 16) {
                        Text("아직 카드가 없어요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("시뮬레이터: ⌘+S로 스크린샷을 찍은 뒤 아래 버튼을 눌러보세요.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            Task { await vm.importScreenshotsFromGallery() }
                        } label: {
                            HStack {
                                if vm.isImportingScreenshots {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "photo.on.rectangle.angled")
                                }
                                Text(vm.isImportingScreenshots ? "가져오는 중…" : "스크린샷에서 카드 가져오기")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(vm.isImportingScreenshots)
                        .padding(.horizontal, 24)
                        // 스크린샷 → 카드 연동 상태 (POST 나갔는지 등 확인용)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("마지막 확인")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(pipelineStatus.lastMessage)
                                .font(.caption)
                                .foregroundColor(.primary)
                            if let err = pipelineStatus.lastError {
                                Text(err)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }
                    .padding(.vertical, 32)
                    Spacer().frame(height: S)
                }

                // ── 섹션 1: Expiring Soon (쿠폰 캐러셀) — 없어도 탭은 표시 ──
                HomeSection(title: "⏳ Expiring Soon") {
                    if vm.coupons.isEmpty {
                        Text("마감 임박한 스크린샷이 아직 없어요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: couponH)
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
                                    isHomeScreen: true // ✅ 홈 화면 쿠폰 전용 이미지 사용
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
                Spacer().frame(height: S) // 24pt

                // ── 섹션 2: Recommended Contents ──
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
                    Spacer().frame(height: S) // 24pt
                }
            }
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

        // 네비게이션
        .navigationDestination(item: $selectedCard) { CardDetailView(card: $0) }
        .navigationDestination(isPresented: $vm.showNotificationView) { NotificationView() }

        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
}
