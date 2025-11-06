import SwiftUI

/// 새 채팅방 생성을 위한 친구 선택 시트
struct ShareFriendSelectionView: View {
    @ObservedObject var vm: ShareViewModel
    @Environment(\.dismiss) private var dismiss
    
    // 선택된 친구들의 ID를 저장
    @State private var selectedFriendIDs: Set<String> = []
    
    // 선택 완료 시 호출될 콜백
    var onComplete: ([Friend]) -> Void

    var body: some View {
        NavigationStack {
            List(vm.friends) { friend in
                // 선택 가능한 행
                SelectableFriendRow(
                    friend: friend,
                    isSelected: selectedFriendIDs.contains(friend.id)
                )
                .onTapGesture {
                    // 탭할 때마다 Set에 추가/제거
                    if selectedFriendIDs.contains(friend.id) {
                        selectedFriendIDs.remove(friend.id)
                    } else {
                        selectedFriendIDs.insert(friend.id)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle("대화 상대 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 닫기 버튼
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                
                // 만들기 버튼
                ToolbarItem(placement: .topBarTrailing) {
                    Button("만들기") {
                        // 선택된 ID를 기반으로 Friend 객체 배열 생성
                        let selectedFriends = vm.friends.filter {
                            selectedFriendIDs.contains($0.id)
                        }
                        // 콜백 실행
                        onComplete(selectedFriends)
                        dismiss()
                    }
                    // 1명 이상 선택해야 활성화
                    .disabled(selectedFriendIDs.isEmpty)
                }
            }
        }
    }
}
