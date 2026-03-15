import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = MyPageViewModel()
    @ObservedObject private var cardManager = CardManager.shared
    @State private var showingError = false
    @State private var showPasswordSheet = false
    @State private var isRemovingDuplicates = false
    @State private var screenshotCount: Int?
    @State private var showResetConfirm = false
    @State private var isImportingScreenshots = false

    var body: some View {
        ScrollView(showsIndicators: false) { content }
            .background(Color(uiColor: .systemGroupedBackground))
            .onAppear { vm.onAppear() }
            .task { screenshotCount = await ScreenshotIndexer.fetchGalleryScreenshotCount() }
            .alert("로컬 카드 초기화", isPresented: $showResetConfirm) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive) {
                    cardManager.clearLocalCardsAndResetScreenshotState()
                }
            } message: {
                Text("로컬에만 있는 카드를 모두 지우고, 스크린샷 처리 목록을 비웁니다. 아래 '스크린샷에서 카드 가져오기'를 누르면 스크린샷당 카드 1개만 다시 만들어집니다.")
            }
            .modifier(MyPageModifier(vm: vm, showingError: $showingError))
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
            .sheet(isPresented: $showPasswordSheet) { MyPagePasswordChangeView() }
    }

    private var content: some View {
        VStack(spacing: 16) {
            // ✅ 헤더에 비밀번호 변경 버튼 액션 전달
            MyPageProfileHeader(
                displayName: vm.displayName,
                email: vm.email,
                profileImage: $vm.profileImage,
                onImageSelected: { image in
                    vm.saveProfileImage(image)
                },
                onChangePassword: {
                    showPasswordSheet = true
                }
            )

            // ✅ AccountSection에서는 onChangePassword 제거
            MyPageAccountSection(
                name: $vm.name,
                userId: vm.userId,
                email: vm.email,
                onSave: {
                    print("🔥 MyPageView: onSave 호출됨")
                    Task {
                        print("🔥 Task 시작")
                        await vm.saveProfile()
                        print("🔥 Task 완료")
                    }
                },
                isSaveEnabled: true
            )

            MyPageUsageCard(
                savedCount: cardManager.allCards.count,
                recommendedCount: cardManager.recommendedCards().count
            )

            // 스크린샷: 가져오기 / 새로고침
            MyPageScreenshotSection(
                isImporting: $isImportingScreenshots,
                onImport: {
                    isImportingScreenshots = true
                    Task {
                        await ScreenshotIndexer.shared.forceImportRecentScreenshots(limit: 20)
                        NotificationCenter.default.post(name: .cardUpdated, object: nil)
                        isImportingScreenshots = false
                    }
                },
                onRefresh: {
                    isImportingScreenshots = true
                    Task {
                        await ScreenshotIndexer.shared.resetAndReimportScreenshots(limit: 50)
                        NotificationCenter.default.post(name: .cardUpdated, object: nil)
                        isImportingScreenshots = false
                    }
                }
            )

            // 카드 관리: 중복 현황 + 중복 제거 + 로컬 초기화
            MyPageCardCleanupSection(
                cardCount: cardManager.allCards.count,
                duplicateCount: cardManager.duplicateCount,
                screenshotCount: screenshotCount,
                isRemovingDuplicates: $isRemovingDuplicates,
                onRemoveDuplicates: {
                    isRemovingDuplicates = true
                    Task {
                        await cardManager.removeDuplicateCards()
                        isRemovingDuplicates = false
                    }
                },
                onResetAndReimport: { showResetConfirm = true }
            )

            MyPageProfileSection(
                gender: $vm.gender,
                birthday: $vm.birthday,
                onSave: {
                    print("🔥 MyPageView: 프로필 onSave 호출됨")
                    Task {
                        print("🔥 프로필 Task 시작")
                        await vm.saveProfile()
                        print("🔥 프로필 Task 완료")
                    }
                },
                isSaveEnabled: true
            )

            MyPageSettingsSection(
                allowLocationRecommend: $vm.allowLocationRecommend,
                allowNotification: $vm.allowNotification,
                onLocationToggle: vm.toggleLocationPermission,
                onNotificationToggle: vm.toggleNotificationPermission
            )

            // 로그아웃 버튼 (맨 아래)
            Button {
                Task { await vm.logout() }
            } label: {
                Text("로그아웃")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .padding(.vertical, 8)
    }
}
