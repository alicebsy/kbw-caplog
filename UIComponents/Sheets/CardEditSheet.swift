import SwiftUI

struct CardEditSheet: View {
    var card: Card
    var onSave: () -> Void = { }
    
    @Environment(\.dismiss) private var dismiss
    
    // 수정 가능한 필드들
    @State private var title: String
    @State private var summary: String
    @State private var selectedCategory: FolderCategory
    @State private var selectedSubcategory: String
    @State private var customFields: [String: String]
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(card: Card, onSave: @escaping () -> Void = { }) {
        self.card = card
        self.onSave = onSave
        
        // 초기값 설정
        _title = State(initialValue: card.title)
        _summary = State(initialValue: card.summary)
        _selectedCategory = State(initialValue: card.category)
        _selectedSubcategory = State(initialValue: card.subcategory)
        _customFields = State(initialValue: card.fields)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 상단 여백
                    Spacer()
                        .frame(height: 20)
                    
                    // 제목
                    VStack(alignment: .leading, spacing: 8) {
                        Text("제목")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        TextField("카드 제목", text: $title)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // 요약
                    VStack(alignment: .leading, spacing: 8) {
                        Text("요약")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        TextField("간단한 설명 (선택사항)", text: $summary)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // 카테고리
                    VStack(alignment: .leading, spacing: 8) {
                        Text("카테고리")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            // 대분류
                            Menu {
                                ForEach(FolderCategory.allCases) { category in
                                    Button(action: {
                                        selectedCategory = category
                                        // 카테고리 변경 시 첫 번째 서브카테고리로 자동 설정
                                        if let firstSub = category.subcategories.first {
                                            selectedSubcategory = firstSub.name
                                        }
                                    }) {
                                        HStack {
                                            Text(category.emoji)
                                            Text(category.rawValue)
                                            if selectedCategory == category {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory.emoji)
                                    Text(selectedCategory.rawValue)
                                        .font(.system(size: 15))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            // 소분류
                            Menu {
                                ForEach(selectedCategory.subcategories) { subcategory in
                                    Button(action: {
                                        selectedSubcategory = subcategory.name
                                    }) {
                                        HStack {
                                            Text(subcategory.name)
                                            if selectedSubcategory == subcategory.name {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedSubcategory)
                                        .font(.system(size: 15))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 커스텀 필드
                    if !customFields.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("상세 정보")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            ForEach(Array(customFields.keys.sorted()), id: \.self) { key in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(key)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                    
                                    TextField(key, text: Binding(
                                        get: { customFields[key] ?? "" },
                                        set: { customFields[key] = $0 }
                                    ))
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("카드 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveCard()
                    }
                    .foregroundColor(Color.myPageActionBlue)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .alert("안내", isPresented: $showAlert) {
                Button("확인") {
                    if alertMessage.contains("저장되었습니다") {
                        onSave()
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func saveCard() {
        guard !title.isEmpty else {
            alertMessage = "제목을 입력해주세요."
            showAlert = true
            return
        }
        
        // 수정된 카드 생성
        var updatedCard = card
        updatedCard.title = title
        updatedCard.summary = summary
        updatedCard.category = selectedCategory
        updatedCard.subcategory = selectedSubcategory
        updatedCard.fields = customFields
        updatedCard.updatedAt = Date()
        
        // CardManager를 통해 저장
        Task {
            await CardManager.shared.updateCard(updatedCard)
            await MainActor.run {
                alertMessage = "카드가 저장되었습니다."
                showAlert = true
            }
        }
        
        print("✅ 카드 수정됨: \(title)")
    }
}

// MARK: - Preview

#Preview {
    CardEditSheet(card: Card.sampleCards[0])
}
