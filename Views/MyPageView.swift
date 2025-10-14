import SwiftUI

struct MyPageView: View {
    @StateObject private var vm = MyPageViewModel()
    @State private var showingError = false

    var body: some View {
        BaseScrollView
            .modifier(MyPageModifier(vm: vm, showingError: $showingError)) // 👈 분리된 Modifier 사용
    }

    // MARK: - ScrollView Content
    private var BaseScrollView: some View {
        ScrollView(showsIndicators: false) {
            content
        }
    }

    // MARK: - Content
    private var content: some View {
        VStack(spacing: 16) {
            // ✅ 프로필 헤더
            MyPageProfileHeader(
                displayName: vm.displayName,
                email: vm.email
            )

            // ✅ 1. 가입정보
            MyPageAccountSection(
                name: $vm.name,
                email: vm.email,
                onChangePassword: { /* TODO */ },
                onSave: { Task { await vm.saveProfile() } },
                isSaveEnabled: vm.canSaveProfile
            )

            // ✅ 2. 사용정보
            MyPageUsageCard(
                savedCount: vm.savedCount,
                recommendedCount: vm.recommendedCount
            )

            // ✅ 3. 프로필
            MyPageProfileSection(
                gender: $vm.gender,
                birthday: $vm.birthday
            )

            // ✅ 4. 설정
            MyPageSettingsSection(
                allowLocationRecommend: $vm.allowLocationRecommend,
                allowNotification: $vm.allowNotification
            )
        }
        .padding(.vertical, 8)
    }
}
