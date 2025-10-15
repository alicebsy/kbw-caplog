import SwiftUI

struct MyPageView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil

    @StateObject private var vm = MyPageViewModel()
    @State private var showingError = false

    // 탭 라우팅
    @State private var goHome = false
    @State private var goFolder = false
    @State private var goSearch = false
    @State private var goShare  = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                content
            }
            // ✨ 이 부분이 추가된 핵심 코드입니다.
            // 화면이 나타날 때 ViewModel의 onAppear 함수를 호출하여 데이터를 불러옵니다.
            .onAppear {
                vm.onAppear()
            }
            .modifier(MyPageModifier(vm: vm, showingError: $showingError))

            // 하단 탭
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

            // 라우팅 목적지
            .navigationDestination(isPresented: $goHome)   { HomeView() }
            .navigationDestination(isPresented: $goFolder) { FolderView() }
            .navigationDestination(isPresented: $goSearch) { SearchView() }
            .navigationDestination(isPresented: $goShare)  { ShareView() }
        }
    }

    // MARK: - Content
    private var content: some View {
        VStack(spacing: 16) {
            MyPageProfileHeader(
                displayName: vm.displayName,
                email: vm.email
            )
            MyPageAccountSection(
                name: $vm.name,
                email: vm.email,
                onChangePassword: { /* TODO */ },
                onSave: { Task { await vm.saveProfile() } },
                isSaveEnabled: vm.canSaveProfile
            )
            MyPageUsageCard(
                savedCount: vm.savedCount,
                recommendedCount: vm.recommendedCount
            )
            MyPageProfileSection(
                gender: $vm.gender,
                birthday: $vm.birthday
            )
            MyPageSettingsSection(
                allowLocationRecommend: $vm.allowLocationRecommend,
                allowNotification: $vm.allowNotification
            )
        }
        .padding(.vertical, 8)
    }
}
