import SwiftUI

struct ShareFriendSearchSheet: View {
    // ✅ (추가) ViewModel을 주입받음
    @ObservedObject var vm: ShareViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var results: [Friend] = []

    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 8) {
                    TextField("친구 ID 검색", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                        // ✅ (수정) 검색어가 바뀔 때마다 바로 search() 호출
                        .onChange(of: keyword) { _, newValue in
                            search(newValue)
                        }
                    
                    // (참고) '검색' 버튼이 꼭 필요하다면 .onChange를 빼고 이 버튼을 활성화하세요.
                    /*
                    Button("검색") {
                        search(keyword)
                    }
                    */
                }
                .padding(.horizontal)
                .padding(.top, 12)

                List(results) { f in
                    FriendRow(name: f.name)   // 상태 표시 없음
                }
                .listStyle(.plain)
            }
            .navigationTitle("친구 추가")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .onAppear {
                // ✅ (수정) 처음 나타날 때 vm.friends (정렬된) 목록을 표시
                search("")
            }
        }
    }

    // ✅ (수정) 검색 로직: 기존 친구를 제외한 전체 사용자 중에서 검색
    private func search(_ k: String) {
        let trimmed = k.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 기존 친구 ID 목록
        let existingFriendIDs = Set(vm.friends.map { $0.id })
        
        // FriendManager의 전체 mock 친구 중에서 기존 친구 제외
        let allUsers = FriendManager.mockFriends.filter { !existingFriendIDs.contains($0.id) }
        
        if trimmed.isEmpty {
            // 키워드가 없으면 기존 친구를 제외한 전체 목록 표시
            results = allUsers
        } else {
            // 키워드가 있으면 ID나 이름으로 필터링
            results = allUsers.filter {
                $0.id.localizedCaseInsensitiveContains(trimmed) ||
                $0.name.localizedCaseInsensitiveContains(trimmed)
            }
        }
    }
}
