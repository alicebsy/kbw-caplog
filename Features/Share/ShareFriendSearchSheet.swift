import SwiftUI

struct ShareFriendSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var isSearching = false
    @State private var searched = false
    @State private var result: ShareFriendDTO? = nil   // ← Friend 이름 충돌 방지

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // 검색창 + 버튼
                HStack(spacing: 8) {
                    TextField("ID 입력", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit { search() }

                    Button(action: search) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)

                // 결과 영역
                Group {
                    if isSearching {
                        ProgressView("검색 중…")
                            .padding(.top, 24)
                    } else if searched && result == nil {
                        Text("검색 결과가 없습니다")
                            .foregroundStyle(.secondary)
                            .padding(.top, 24)
                            .frame(maxWidth: .infinity)
                    } else if let friend = result {
                        VStack(spacing: 12) {
                            AsyncImage(url: friend.avatarURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 96, height: 96)
                                case .success(let img):
                                    img.resizable()
                                        .scaledToFill()
                                        .frame(width: 96, height: 96)
                                        .clipShape(Circle())
                                case .failure:
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(Image(systemName: "person.fill").font(.title))
                                        .frame(width: 96, height: 96)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            Text(friend.name)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    } else {
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Button("닫기") { dismiss() }
                    .padding(.bottom, 8)
            }
            .navigationTitle("친구 추가")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Search
    private func search() {
        let q = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        isSearching = true
        searched = true
        result = nil

        // 실제 API 연동 지점
        // 아래 더미를 네트워크 호출로 교체하세요.
        Task {
            let found = await ShareFriendSearchService.search(keyword: q)
            await MainActor.run {
                self.result = found
                self.isSearching = false
            }
        }
    }
}

// MARK: - Model (이 파일 한정)
fileprivate struct ShareFriendDTO: Identifiable, Equatable {
    let id: String
    let name: String
    let avatarURL: URL?
}

// MARK: - Dummy Service (교체 대상)
fileprivate enum ShareFriendSearchService {
    static let sample: [ShareFriendDTO] = [
        .init(id: "minha", name: "우민하", avatarURL: URL(string: "https://picsum.photos/200")),
        .init(id: "kbw", name: "강배우", avatarURL: URL(string: "https://picsum.photos/201")),
        .init(id: "bsy", name: "배서연", avatarURL: URL(string: "https://picsum.photos/202")),
    ]

    static func search(keyword: String) async -> ShareFriendDTO? {
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s 모의 지연
        let lower = keyword.lowercased()
        return sample.first {
            $0.id.lowercased().contains(lower) || $0.name.contains(keyword)
        }
    }
}
