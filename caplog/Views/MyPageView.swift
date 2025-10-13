import SwiftUI

struct MyPageView: View {
    @StateObject private var vm = MyPageViewModel()
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MyPageProfileHeader(displayName: vm.name, email: vm.email)

                    MyPageAccountSection(
                        name: $vm.name,
                        email: vm.email,
                        onChangePassword: { /* TODO: 비번 변경 화면 */ },
                        onSave: { Task { await vm.saveProfile() } }
                    )

                    MyPageProfileSection(gender: $vm.gender, birthday: $vm.birthday)

                    MyPageUsageCard(savedCount: vm.savedCount, recommendedCount: vm.recommendedCount)

                    MyPageSettingsSection(
                        allowLocationRecommend: $vm.allowLocationRecommend,
                        allowNotification: $vm.allowNotification
                    )

                    // 내가 저장한 스크린샷 리스트
                    SectionHeader(title: "내 스크린샷")
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ScreenshotGrid(items: vm.screenshots) { item in
                        Task { await vm.fetchMoreIfNeeded(current: item) }
                    }
                }
                .padding(.vertical, 12)
                .refreshable { await vm.refreshAll() }
            }
            .background(Color(uiColor: .systemGray6))
            .navigationTitle("My Page")
            .onAppear { vm.onAppear() }
            .onReceive(NotificationCenter.default.publisher(for: .logoutTapped)) { _ in
                Task { await vm.logout() }
            }
            .onChange(of: vm.errorMessage) { _, new in
                showingError = (new != nil)
            }
            .alert("오류", isPresented: $showingError, actions: {
                Button("확인", role: .cancel) { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }
}

// 썸네일 그리드
struct ScreenshotGrid: View {
    let items: [ScreenshotItem]
    var onAppearItem: (ScreenshotItem) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items) { item in
                AsyncImage(url: item.thumbnailUrl) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color(uiColor: .systemGray5))
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
