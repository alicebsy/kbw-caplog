import SwiftUI

/// 카드 전송을 위한 카드 선택 시트 (검색/필터 기능 추가됨)
struct ShareCardSelectionSheet: View {
    private let cardManager = CardManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // ✅ 콜백이 카드 "배열"을 받도록 변경
    var onComplete: ([Card]) -> Void

    // --- 필터링 상태 ---
    @State private var searchQuery = ""
    @State private var selectedCategory: FolderCategory? = nil
    @State private var selectedSub: String? = nil
    
    // ✅ 여러 카드를 선택하기 위한 Set
    @State private var selectedIDs: Set<UUID> = []
    
    /// 필터링 로직
    private var filteredCards: [Card] {
        var cards = cardManager.allCards
        if let category = selectedCategory {
            cards = cards.filter { $0.category == category }
            if let sub = selectedSub {
                cards = cards.filter { $0.subcategory == sub }
            }
        }
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            let lowerQuery = trimmedQuery.lowercased()
            cards = cards.filter {
                $0.title.lowercased().contains(lowerQuery) ||
                $0.summary.lowercased().contains(lowerQuery) ||
                $0.tags.contains { $0.lowercased().contains(lowerQuery) }
            }
        }
        return cards
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // --- 검색창 ---
                TextField("카드 제목, 요약, 태그 검색...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // --- 폴더 필터 메뉴 ---
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedCategory = nil
                            selectedSub = nil
                        } label: {
                            Image(systemName: "xmark")
                            Text("전체")
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedCategory == nil ? .blue : .gray)

                        ForEach(FolderCategory.allCases) { category in
                            Menu {
                                Button("전체 \(category.rawValue)") {
                                    selectedCategory = category
                                    selectedSub = nil
                                }
                                ForEach(category.subcategories) { sub in
                                    Button(sub.name) {
                                        selectedCategory = category
                                        selectedSub = sub.name
                                    }
                                }
                            } label: {
                                if selectedCategory == category {
                                    Text(selectedSub ?? category.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                    Image(systemName: "chevron.down")
                                } else {
                                    Text(category.rawValue)
                                        .font(.system(size: 14))
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedCategory == category ? category.color : .gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }

                Divider()

                // --- 카드 목록 ---
                if cardManager.isLoading && cardManager.allCards.isEmpty {
                    VStack { // ✅ (수정) 로딩 뷰도 중앙 정렬
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredCards.isEmpty {
                    
                    // ✅ (수정) Empty State UI를 중앙 정렬
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 30, weight: .regular))
                            .foregroundStyle(.secondary)
                        Text(searchQuery.isEmpty ? "필터에 맞는 카드가 없습니다." : "검색 결과가 없습니다.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    List(filteredCards) { card in
                        UnifiedCardView(
                            card: card,
                            style: .compact,
                            onTap: {
                                toggleSelection(card) // 탭하면 선택 토글
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(selectedIDs.contains(card.id) ? Color.blue : Color.clear, lineWidth: 3)
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .contentMargins(.bottom, 16)
                }
            }
            .navigationTitle("카드 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // "취소" 버튼
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                
                // "보내기" 버튼
                ToolbarItem(placement: .topBarTrailing) {
                    Button(selectedIDs.isEmpty ? "보내기" : "보내기 (\(selectedIDs.count))") {
                        let selectedCards = cardManager.allCards.filter {
                            selectedIDs.contains($0.id)
                        }
                        onComplete(selectedCards)
                        dismiss()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .task {
                await cardManager.loadAllCards()
            }
        }
    }
    
    private func toggleSelection(_ card: Card) {
        if selectedIDs.contains(card.id) {
            selectedIDs.remove(card.id)
        } else {
            selectedIDs.insert(card.id)
        }
    }
}
