import Foundation
import Combine

// 화면 로직만 담당
final class SearchViewModel: ObservableObject {
    // Input / Output
    @Published var query: String = ""
    @Published var results: [FolderItem] = []  // ✅ SearchResultItem → FolderItem
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

// MARK: - Service Protocol
protocol SearchServiceType {
    func search(query: String) -> AnyPublisher<[FolderItem], Error>  // ✅ FolderItem 반환
}

// 🔧 백엔드 붙기 전까지는 더미 서비스 사용
struct SearchServiceMock: SearchServiceType {
    func search(query: String) -> AnyPublisher<[FolderItem], Error> {
        // 테스트용 더미 데이터 (실제로는 백엔드에서 받아옴)
        let dummyResults: [FolderItem] = [
            FolderItem(
                category: .info,
                subcategory: "맛집",
                title: "이목리 막국수",
                summary: "동치미막국수, 명태회막국수",
                fields: [
                    "장소명": "이목리 막국수",
                    "주소": "강원 속초시 이목로 104-43",
                    "대표메뉴": "동치미막국수"
                ],
                date: "2025.09.28",
                imageName: "이목리막국수"
            ),
            FolderItem(
                category: .contents,
                subcategory: "글",
                title: "마음에 남는 문장",
                summary: "'너무 늦은 시도란 없다.'",
                fields: ["topic": "동기부여"],
                date: "2025.09.05",
                imageName: "글귀"
            )
        ]
        
        // 검색어에 따라 필터링 (더미)
        let filtered = dummyResults.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            item.summary.localizedCaseInsensitiveContains(query) ||
            item.subcategory.localizedCaseInsensitiveContains(query)
        }
        
        return Just(filtered)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)  // 네트워크 지연 시뮬레이션
            .eraseToAnyPublisher()
    }
}
