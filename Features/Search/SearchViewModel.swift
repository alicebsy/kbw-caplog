import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var selectedPair: CategoryPair? = nil
    @Published var results: [SearchItem] = []
    @Published var isLoading = false
    @Published var canLoadMore = false

    private var page = 0
    private let size = 20
    private let api: SearchAPIType

    init(api: SearchAPIType = SearchAPI()) {
        self.api = api
    }

    func setCategory(major: MajorCategory, sub: SubCategory) {
        selectedPair = CategoryPair(major: major, sub: sub)
        resetAndSearch()
    }

    func resetAndSearch() {
        page = 0
        results.removeAll()
        canLoadMore = false
        Task { await performSearch(reset: true) }
    }

    func loadMoreIfPossible() {
        guard !isLoading, canLoadMore else { return }
        Task { await performSearch(reset: false) }
    }

    private func performSearch(reset: Bool) async {
        isLoading = true
        defer { isLoading = false }

        let tokens: [String] = selectedPair.map(FolderCategoryMap.tokens(for:)) ?? []
        let dto = SearchQueryDTO(query: query, tags: tokens, page: page, size: size)

        do {
            let resp = try await api.search(dto)
            if reset { results = resp.items } else { results += resp.items }
            if let next = resp.nextPage { page = next; canLoadMore = true }
            else { canLoadMore = false }
        } catch {
            // TODO: 필요 시 오류 상태 바인딩
            canLoadMore = false
        }
    }
}
