import Foundation
import Combine

// 화면 로직만 담당
final class SearchViewModel: ObservableObject {
    // Input / Output
    @Published var query: String = ""
    @Published var results: [SearchResultItem] = []
    @Published var isLoading: Bool = false
    @Published var hasSearched: Bool = false
    @Published var recentQueries: [String] = []

    private let service: SearchServiceType
    private var cancellables = Set<AnyCancellable>()

    init(service: SearchServiceType = SearchServiceMock()) {
        self.service = service
        loadRecent()
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
        service.search(query: q)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(_) = completion { self?.results = [] }
            } receiveValue: { [weak self] items in
                self?.results = items
                self?.pushRecent(q)
            }
            .store(in: &cancellables)
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

// MARK: - Model
struct SearchResultItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let snippet: String
    let createdAt: Date
}

// MARK: - Service Protocol
protocol SearchServiceType {
    func search(query: String) -> AnyPublisher<[SearchResultItem], Error>
}

// 🔧 백엔드 붙기 전까지는 더미 서비스 사용
struct SearchServiceMock: SearchServiceType {
    func search(query: String) -> AnyPublisher<[SearchResultItem], Error> {
        // 지금은 빈 결과만 반환 (네트워크 연동 전)
        return Just<[SearchResultItem]>([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
