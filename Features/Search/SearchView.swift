import SwiftUI

struct SearchView: View {
    var onSelectTab: ((CaplogTab) -> Void)? = nil

    // 탭 라우팅 (기존 유지)
    @State private var goHome = false
    @State private var goFolder = false
    @State private var goShare  = false
    @State private var goMyPage = false

    // ✅ 추가: 검색 상태
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // 상단 검색 입력창
                    HStack(spacing: 8) {
                        TextField("검색어를 입력하세요", text: $vm.query)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.search)
                            .onSubmit { vm.resetAndSearch() }

                        if !vm.query.isEmpty {
                            Button {
                                vm.query = ""
                                vm.resetAndSearch()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .imageScale(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // 카테고리 칩 (대분류/소분류)
                    SearchFilterChips(selected: $vm.selectedPair)
                        .onChange(of: vm.selectedPair) { _ in
                            vm.resetAndSearch()
                        }
                        .padding(.bottom, 8)

                    // 결과 리스트
                    List {
                        ForEach(vm.results) { item in
                            SearchResultRow(item: item)
                                .onAppear {
                                    if item.id == vm.results.last?.id {
                                        vm.loadMoreIfPossible()
                                    }
                                }
                        }

                        if vm.isLoading {
                            HStack { Spacer(); ProgressView(); Spacer() }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("검색")
            .navigationBarTitleDisplayMode(.inline)

            // 하단 탭 (기존 유지)
            .safeAreaInset(edge: .bottom) {
                CaplogTabBar(selected: .search) { tab in
                    onSelectTab?(tab)
                    switch tab {
                    case .home:   goHome   = true
                    case .folder: goFolder = true
                    case .share:  goShare  = true
                    case .myPage: goMyPage = true
                    case .search: break
                    }
                }
            }

            // 라우팅 (기존 유지)
            .navigationDestination(isPresented: $goHome)   { HomeView() }
            .navigationDestination(isPresented: $goFolder) { FolderView() }
            .navigationDestination(isPresented: $goShare)  { ShareView() }
            .navigationDestination(isPresented: $goMyPage) { MyPageView() }
        }
        .onAppear {
            if vm.results.isEmpty { vm.resetAndSearch() }
        }
    }
}
