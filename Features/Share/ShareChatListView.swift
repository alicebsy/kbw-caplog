import SwiftUI
import Combine

/// 채팅 목록 화면 (상단의 "채팅" 탭 컨텐츠)
@MainActor
struct ShareChatListView: View {
    @ObservedObject var vm: ShareViewModel   // 🔹 주입받기

    var body: some View {
        List {
            ForEach(vm.threads) { t in
                NavigationLink {
                    // 🔹 같은 vm 전달 → openThread에서 읽음 0 반영됨
                    ChatRoomView(vm: vm, thread: t)
                } label: {
                    HStack(spacing: 12) {
                        Circle().frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // 첫 줄: 이름 + 시간
                            HStack(spacing: 0) {
                                Text(t.title)
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Text(vm.timeString(for: t.lastMessageAt))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // 둘째 줄: 메시지 + 안읽음표시(오른쪽 정렬)
                            HStack(spacing: 0) {
                                Text(t.lastMessageText ?? "메시지가 없습니다")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if t.unreadCount > 0 {
                                    Text("\(t.unreadCount)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color.unreadBadgeRed))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await vm.loadAll() }
    }
}
