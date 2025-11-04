import SwiftUI

struct MyPageView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = MyPageViewModel()
    @State private var showingError = false
    @State private var showPasswordSheet = false

    @State private var goHome = false
    @State private var goFolder = false
    @State private var goSearch = false
    @State private var goShare  = false

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
            .safeAreaInset(edge: .bottom) {
                CaplogTabBar(selected: .myPage) { tab in
                    onSelectTab?(tab)
                    switch tab {
                    case .home:   goHome   = true
                    case .folder: goFolder = true
                    case .search: goSearch = true
                    case .share:  goShare  = true
                    case .myPage: break
                    }
                }
            }
            .navigationDestination(isPresented: $goHome)   { HomeView() }
            .navigationDestination(isPresented: $goFolder) { FolderView() }
            .navigationDestination(isPresented: $goSearch) { SearchView() }
            .navigationDestination(isPresented: $goShare)  { ShareView() }
            .sheet(isPresented: $showPasswordSheet) { MyPagePasswordChangeView() }
    }

    private var content: some View {
        VStack(spacing: 16) {
            MyPageProfileHeader(displayName: vm.displayName, email: vm.email)

            MyPageAccountSection(
                name: $vm.name,
                email: vm.email,
                onChangePassword: { showPasswordSheet = true },
                // ✅ Task 내부에서 await 호출
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

            MyPageUsageCard(savedCount: vm.savedCount, recommendedCount: vm.recommendedCount)

            MyPageProfileSection(
                gender: $vm.gender,
                birthday: $vm.birthday,
                // ✅ Task 내부에서 await 호출
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
        }
        .padding(.vertical, 8)
    }
}
