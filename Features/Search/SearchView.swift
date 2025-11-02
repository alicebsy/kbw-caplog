import SwiftUI
import Combine

struct SearchView: View {
    @FocusState private var isFocused: Bool
    @StateObject private var vm = SearchViewModel()

    // 로고 표시 규칙: 포커스 중엔 숨김, 검색 완료/포커스 해제 시 노출
    private var showLogo: Bool { !isFocused }

    var body: some View {
        VStack(spacing: 0) {

            // ===== 상단 행: 로고 + 검색창 + 돋보기(같은 높이) =====
            HStack(spacing: 10) {

                // Ⓛ Caplog 로고: 포커스 시 숨기고, 해제 시 다시 표시
                Image("caplog_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: showLogo ? 76 : 0, height: 22)   // 숨김 시 폭 0으로 접기
                    .opacity(showLogo ? 1 : 0)
                    .animation(.easeInOut(duration: 0.18), value: showLogo)

                // ⓒ 검색창
                HStack(spacing: 8) {
                    // 왼쪽 아이콘(필요 없다고 했으므로 없음)
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
                                .foregroundStyle(.secondary)
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

                // Ⓡ 돋보기 버튼: 반드시 이 버튼(또는 키보드 Search)으로만 검색 실행
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
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .animation(.easeInOut(duration: 0.18), value: isFocused)

            // ===== 콘텐츠 =====
            Group {
                if !vm.hasSearched {
                    // 1) 검색 전: 최근 검색만 표시 (로고는 위 행에 있으므로 여기선 없음)
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
                    // 2) 검색 후
                    if vm.isLoading && vm.results.isEmpty {
                        SearchLoadingView().padding(.top, 24)
                    } else if vm.results.isEmpty {
                        SearchEmptyStateView().padding(.top, 24)
                    } else {
                        List {
                            ForEach(vm.results) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.system(size: 17, weight: .semibold))
                                    if !item.snippet.isEmpty {
                                        Text(item.snippet)
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Text(item.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        // 네비게이션 바에는 아무 아이콘도 추가하지 않음(중복/위치 어긋남 방지)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarBackButtonHidden(false)   // 시스템 < 한 개만
    }
}

// MARK: - Recent Search List (기존 그대로)
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
                            Text(term).foregroundStyle(.primary)
                        }
                    }
                    Spacer()
                    Button(action: { remove(term) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
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
