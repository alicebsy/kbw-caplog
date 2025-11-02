import SwiftUI
import Combine

/// 채팅 목록 화면 (상단의 “채팅” 탭 컨텐츠)
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
                            HStack {
                                Text(t.title).font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Text(vm.timeString(for: t.lastMessageAt))     // 우측 작은 시간
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                            Text(t.lastMessageText ?? "메시지가 없습니다")
                                .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        }
                        if t.unreadCount > 0 {
                            Text("\(t.unreadCount)")
                                .font(.footnote)
                                .padding(6)
                                .background(Capsule().fill(Color.blue.opacity(0.15)))
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
