import SwiftUI

struct MyPageView: View {
    @StateObject private var vm = MyPageViewModel()
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                content                                      // ← 복잡한 body를 분리
            }
            .background(Color.homeBackgroundLight.ignoresSafeArea())
            .navigationTitle("My Page")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: onAppear)
            .onReceive(NotificationCenter.default.publisher(for: .logoutTapped)) { _ in
                Task { await vm.logout() }
            }
            .onChange(of: vm.errorMessage) { _, new in
                showingError = (new != nil)
            }
            .alert("오류", isPresented: $showingError) {
                Button("확인", role: .cancel) { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Split Views
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 16) {
            profileHeader
            accountSection
            profileSection
            usageCard
            settingsSection
            screenshotHeader
            screenshotGrid
        }
        .padding(.vertical, 12)
        .refreshable { await vm.refreshAll() }
    }

    private var profileHeader: some View {
        MyPageProfileHeader(displayName: vm.name, email: vm.email)
    }

    private var accountSection: some View {
        MyPageAccountSection(
            name: $vm.name,
            email: vm.email,
            onChangePassword: onChangePassword,
            onSave: onSaveProfile
        )
    }

    private var profileSection: some View {
        MyPageProfileSection(gender: $vm.gender, birthday: $vm.birthday)
    }

    private var usageCard: some View {
        MyPageUsageCard(savedCount: vm.savedCount, recommendedCount: vm.recommendedCount)
    }

    private var settingsSection: some View {
        MyPageSettingsSection(
            allowLocationRecommend: $vm.allowLocationRecommend,
            allowNotification: $vm.allowNotification
        )
    }

    private var screenshotHeader: some View {
        MyPageSectionHeader(title: "내 스크린샷")
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var screenshotGrid: some View {
        ScreenshotGrid(items: vm.screenshots) { item in
            Task { await vm.fetchMoreIfNeeded(current: item) }
        }
    }

    // MARK: - Actions
    private func onAppear() { vm.onAppear() }
    private func onChangePassword() {
        // TODO: 비밀번호 변경 화면으로 이동
    }
    private func onSaveProfile() {
        Task { await vm.saveProfile() }
    }
}

// MARK: - Thumbnail Grid
struct ScreenshotGrid: View {
    let items: [ScreenshotItem]
    var onAppearItem: (ScreenshotItem) -> Void

    private let columns = [GridItem(.flexible()),
                           GridItem(.flexible()),
                           GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items) { item in
                AsyncImage(url: item.thumbnailUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.homeBackgroundMid)
                }
                .frame(height: 110)
                .clipped()
                .cornerRadius(10)
                .onAppear { onAppearItem(item) }
                .accessibilityLabel(item.title ?? "스크린샷")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}
