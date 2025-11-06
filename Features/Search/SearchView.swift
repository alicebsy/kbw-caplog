import SwiftUI
import Combine

struct SearchView: View {
    @FocusState private var isFocused: Bool
    @StateObject private var vm = SearchViewModel()
    
    // ✅ dismiss 환경 변수 추가
    @Environment(\.dismiss) private var dismiss

    // ✅ 상세/공유/편집/이미지 팝업 상태
    @State private var selectedCard: Card? = nil
    @State private var shareTarget: Card? = nil
    @State private var editingCard: Card? = nil
    @State private var fullscreenImage: String? = nil

    private var showLogo: Bool { !isFocused }

    var body: some View {
        VStack(spacing: 0) {

            // ===== 상단 행: 로고 + 검색창 + 돋보기 =====
            HStack(spacing: 2) {

                // Caplog 로고
                Image("caplog_letter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: showLogo ? 76 : 0, height: 22)
                    .opacity(showLogo ? 1 : 0)
                    .animation(.easeInOut(duration: 0.18), value: showLogo)

                // 검색창
                HStack(spacing: 5) {
                    TextField("검색어를 입력해주세요.", text: $vm.query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                        .focused($isFocused)
                        .onSubmit {
                            isFocused = false
                            vm.resetAndSearch()
                        }

                    if !vm.query.isEmpty {
                        Button {
                            vm.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.brandTextSub)  // ✅ 명시적으로 회색 지정
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.brandLine, lineWidth: 1)
                        )
                )

                // 돋보기 버튼
                Button {
                    isFocused = false
                    vm.resetAndSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("검색")
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .animation(.easeInOut(duration: 0.18), value: isFocused)

            // ===== 콘텐츠 =====
            Group {
                if !vm.hasSearched {
                    RecentSearchList(
                        items: vm.recentQueries,
                        tap: { term in
                            vm.query = term
                            isFocused = false
                            vm.resetAndSearch()
                        },
                        remove: { term in
                            vm.removeRecent(term)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    if vm.isLoading && vm.results.isEmpty {
                        SearchLoadingView().padding(.top, 24)
                    } else if vm.results.isEmpty {
                        SearchEmptyStateView().padding(.top, 24)
                    } else {
                        List {
                            ForEach(vm.results) { item in
                                UnifiedCardView(
                                    card: item,
                                    style: .row,
                                    onTap: { selectedCard = item },  // ✅ 상세 화면
                                    onShare: { shareTarget = item }, // ✅ 공유
                                    onMore: { editingCard = item },  // ✅ 편집
                                    onTapImage: {  // ✅ 이미지 전체보기
                                        if let first = item.screenshotURLs.first {
                                            fullscreenImage = first
                                        } else {
                                            fullscreenImage = item.thumbnailName
                                        }
                                    }
                                )
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .onAppear {
                                        if item.id == vm.results.last?.id {
                                            vm.loadMoreIfPossible()
                                        }
                                    }
                            }
                            if vm.isLoading {
                                HStack { Spacer(); ProgressView(); Spacer() }
                                    .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
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
        
        // ✅ 공유 시트
        .sheet(item: $shareTarget) { target in
            ShareSheetView(
                target: target,
                friends: []
            ) { ids, msg in
                print("Search 공유 → 대상: \(ids), 메시지: \(msg)")
            }
            .presentationDetents([.height(350)])
        }
        
        // ✅ 편집 시트
        .sheet(item: $editingCard) { card in
            CardEditSheet(card: card) { updated in
                print("업데이트: \(updated)")
            }
            .presentationDetents([.medium, .large])
        }
        
        // ✅ 전체 이미지 팝업
        .fullScreenCover(isPresented: Binding(
            get: { fullscreenImage != nil },
            set: { if !$0 { fullscreenImage = nil } }
        )) {
            if let name = fullscreenImage {
                HomeImagePopupView(imageName: name)
            }
        }
        
        // ✅ 상세 화면 이동
        .navigationDestination(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
    }
}

// MARK: - Recent Search List
private struct RecentSearchList: View {
    let items: [String]
    let tap: (String) -> Void
    let remove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !items.isEmpty {
                Text("Recent search")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            }

            ForEach(items, id: \.self) { term in
                HStack {
                    Button(action: { tap(term) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Text(term)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: { remove(term) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
                )
            }
        }
    }
}

// MARK: - SearchResultItemRow 삭제됨
// → UnifiedCardView(style: .compact) 사용
