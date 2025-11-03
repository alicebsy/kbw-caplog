import SwiftUI

struct MyPageView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil
    
    // ✅ dismiss 환경 변수 추가
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = MyPageViewModel()
    @State private var showingError = false

    // 탭 라우팅
    @State private var goHome = false
    @State private var goFolder = false
    @State private var goSearch = false
    @State private var goShare  = false

    var body: some View {
        // ✅ NavigationStack 제거 - 상위에서 관리
        ScrollView(showsIndicators: false) {
            content
        }
        .onAppear {
            vm.onAppear()
        }
        .modifier(MyPageModifier(vm: vm, showingError: $showingError))
        
        // ✅ 커스텀 백버튼 (아이콘만)
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

        // 하단 탭바
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

    // MARK: - Content
    private var content: some View {
        VStack(spacing: 16) {
            // 프로필 헤더
            MyPageProfileHeader(
                displayName: vm.displayName,
                email: vm.email
            )

            // 가입정보 섹션
            MyPageAccountSection(
                name: $vm.name,
                email: vm.email,
                onChangePassword: { /* TODO: 비밀번호 변경 화면 연결 예정 */ },
                onSave: { Task { await vm.saveProfile() } },
                isSaveEnabled: vm.canSaveProfile
            )

            // 사용정보 카드
            MyPageUsageCard(
                savedCount: vm.savedCount,
                recommendedCount: vm.recommendedCount
            )

            // 프로필 섹션
            MyPageProfileSection(
                gender: $vm.gender,
                birthday: $vm.birthday
            )

            // 설정 섹션
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
