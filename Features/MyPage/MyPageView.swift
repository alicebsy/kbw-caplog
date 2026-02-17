import SwiftUI

struct MyPageView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = MyPageViewModel()
    @State private var showingError = false
    @State private var showPasswordSheet = false

    var body: some View {
        ScrollView(showsIndicators: false) { content }
            .onAppear { vm.onAppear() }
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
                savedCount: CardManager.shared.allCards.count,
                recommendedCount: CardManager.shared.recommendedCards().count
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
