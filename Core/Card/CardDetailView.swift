import SwiftUI

/// 카드 상세 화면
struct CardDetailView: View {
    let card: Card
    
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showEditSheet = false
    @State private var selectedImage: String? = nil
    @State private var showAddTagSheet = false
    @State private var editableTags: [String]
    @State private var tagToDelete: String? = nil
    @State private var showDeleteConfirm = false
    @State private var showCardDeleteConfirm = false
    
    init(card: Card) {
        self.card = card
        _editableTags = State(initialValue: card.tags)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 썸네일 이미지
                    Image(card.thumbnailName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            selectedImage = card.thumbnailName
                        }
                    
                    // 기본 정보
                    VStack(alignment: .leading, spacing: 12) {
                        // 카테고리
                        HStack {
                            Text(card.category.emoji)
                                .font(.system(size: 20))
                            Text(card.category.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(card.subcategory)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        
                        // 제목
                        Text(card.title)
                            .font(.system(size: 24, weight: .bold))
                        
                        // 요약
                        if !card.summary.isEmpty {
                            Text(card.summary)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        // 커스텀 필드
                        if !card.fields.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(card.fields.keys.sorted()), id: \.self) { key in
                                    if let value = card.fields[key], !value.isEmpty {
                                        HStack(alignment: .top) {
                                            Text(key)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 80, alignment: .leading)
                                            Text(value)
                                                .font(.system(size: 14))
                                                .foregroundStyle(.primary)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                        }
                        
                        // 태그 섹션
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("태그")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            
                            if editableTags.isEmpty {
                                // 태그가 없을 때
                                Button(action: { showAddTagSheet = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                        Text("태그 추가")
                                            .font(.system(size: 13))
                                    }
                                    .foregroundStyle(Color.brandAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.brandAccent.opacity(0.15))
                                    .clipShape(Capsule())
                                }
                            } else {
                                // 태그가 있을 때
                                FlowLayout(spacing: 8) {
                                    // 기존 태그들 (X 버튼 포함)
                                    ForEach(editableTags, id: \.self) { tag in
                                        HStack(spacing: 6) {
                                            Text("#\(tag)")
                                                .font(.system(size: 13))
                                            
                                            Button(action: {
                                                tagToDelete = tag
                                                showDeleteConfirm = true
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(Color.brandAccent.opacity(0.7))
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.brandAccent.opacity(0.15))
                                        .foregroundStyle(Color.brandAccent)
                                        .clipShape(Capsule())
                                    }
                                    
                                    // 추가 버튼
                                    Button(action: { showAddTagSheet = true }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color.brandAccent)
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
            }
            
            // ✅ Toolbar 대신 overlay로 커스텀 버튼 구현
            VStack {
                HStack {
                    // 뒤로가기 버튼 영역
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    // 타이틀
                    Text("상세 정보")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    // 우측 버튼들
                    HStack(spacing: 12) {
                        // 수정 버튼
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.caplogGrayDark)
                            .onTapGesture {
                                showEditSheet = true
                            }
                        
                        // 삭제 버튼
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.registerRed.opacity(0.75))
                            .onTapGesture {
                                showCardDeleteConfirm = true
                            }
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 44)
                .background(Color(.systemBackground))
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: Binding(
            get: { selectedImage != nil },
            set: { if !$0 { selectedImage = nil } }
        )) {
            if let imageName = selectedImage {
                FullScreenImageView(imageName: imageName)
            }
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddTagSheet(currentTags: editableTags) { newTag in
                withAnimation(.easeInOut(duration: 0.2)) {
                    if !editableTags.contains(newTag) {
                        editableTags.append(newTag)
                        saveTagChanges()
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            CardEditSheet(card: card)
        }
        // 태그 삭제 확인 알림
        .alert("태그 삭제", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) {
                tagToDelete = nil
            }
            Button("삭제", role: .destructive) {
                if let tag = tagToDelete {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        editableTags.removeAll { $0 == tag }
                        saveTagChanges()
                    }
                }
                tagToDelete = nil
            }
        } message: {
            if let tag = tagToDelete {
                Text("'\(tag)' 태그를 삭제하시겠습니까?")
            }
        }
        // 카드 삭제 확인 알림
        .alert("카드 삭제", isPresented: $showCardDeleteConfirm) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                deleteCard()
            }
        } message: {
            Text("'\(card.title)' 카드를 삭제하시겠습니까?\n삭제된 카드는 복구할 수 없습니다.")
        }
        .onAppear {
            CardManager.shared.markCardAsViewed(card)
        }
    }
    
    private func saveTagChanges() {
        var updatedCard = card
        updatedCard.tags = editableTags
        Task {
            await CardManager.shared.updateCard(updatedCard)
        }
        print("✅ 태그 변경됨: \(editableTags)")
    }
    
    private func deleteCard() {
        Task {
            await CardManager.shared.deleteCard(id: card.id)
            print("✅ 카드 삭제됨: \(card.title)")
            dismiss()
        }
    }
}

// MARK: - Flow Layout (태그 레이아웃)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Full Screen Image View

struct FullScreenImageView: View {
    let imageName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding()
        }
        .onTapGesture {
            dismiss()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CardDetailView(card: Card.sampleCards[0])
    }
}
