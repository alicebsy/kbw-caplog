import Foundation
import Combine

// 화면 로직만 담당
@MainActor
final class SearchViewModel: ObservableObject {
    // Input / Output
    @Published var query: String = ""
    @Published var results: [Card] = []
    @Published var isLoading: Bool = false
    @Published var hasSearched: Bool = false
    @Published var recentQueries: [String] = []

    private let cardManager: CardManager // ✅ 공유 인스턴스
    private var cancellables = Set<AnyCancellable>()

    init() {
        // ✅ 수정: 새 인스턴스 생성 -> 공유 인스턴스 사용
        self.cardManager = CardManager.shared
        self.loadRecent()
        
        // CardManager 데이터 로드
        Task {
            await cardManager.loadAllCards()
        }
    }

    // 실행 트리거: 돋보기 버튼 or 키보드 Search
    func resetAndSearch() {
        hasSearched = true
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !q.isEmpty else {
            results = []
            isLoading = false
            return
        }

        isLoading = true
        
        // CardManager를 통한 검색
        results = cardManager.searchCards(query: q)
        pushRecent(q)
        
        isLoading = false
    }

    func loadMoreIfPossible() {
        // 페이지네이션 필요 시 구현
    }

    // MARK: - Recent
    private func loadRecent() {
        let saved = UserDefaults.standard.stringArray(forKey: "recent_searches") ?? []
        recentQueries = saved
    }

    private func pushRecent(_ q: String) {
        var arr = UserDefaults.standard.stringArray(forKey: "recent_searches") ?? []
        arr.removeAll { $0 == q }
        arr.insert(q, at: 0)
        if arr.count > 10 { arr.removeLast(arr.count - 10) }
        UserDefaults.standard.set(arr, forKey: "recent_searches")
        recentQueries = arr
    }

    func removeRecent(_ q: String) {
        var arr = UserDefaults.standard.stringArray(forKey: "recent_searches") ?? []
        arr.removeAll { $0 == q }
        UserDefaults.standard.set(arr, forKey: "recent_searches")
        recentQueries = arr
    }
}
