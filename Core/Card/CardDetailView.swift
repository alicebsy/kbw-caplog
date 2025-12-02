import SwiftUI

// MARK: - FlowLayout (자동 줄바꿈 레이아웃)

/// 자동 줄바꿈 레이아웃 (태그용)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowLayoutResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowLayoutResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }
    
    struct FlowLayoutResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // 다음 줄로 이동
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            // 전체 크기 계산
            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// MARK: - FullScreenImageView (전체 화면 이미지 뷰어)

/// 전체 화면 이미지 뷰어
struct FullScreenImageView: View {
    let imageName: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            // 최소/최대 배율 제한
                            scale = min(max(scale, 1.0), 4.0)
                            lastScale = scale
                            
                            // 배율이 1이면 오프셋 초기화
                            if scale == 1.0 {
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    // 더블 탭으로 줌 인/아웃
                    withAnimation(.spring(response: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }
            
            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - CardDetailView (카드 상세 화면)

/// 카드 상세 화면 - 항상 CardManager에서 최신 데이터를 가져옴
struct CardDetailView: View {

    let cardID: UUID
    
    // CardManager를 관찰하여 실시간 업데이트
    @ObservedObject private var cardManager = CardManager.shared

    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var selectedImage: String? = nil
    @State private var showAddTagSheet = false
    @State private var tagToDelete: String? = nil
    @State private var showDeleteConfirm = false
    @State private var showCardDeleteConfirm = false

    init(card: Card) {
        self.cardID = card.id
    }
    
    // 항상 최신 카드 데이터를 가져오는 계산 속성
    private var card: Card? {
        cardManager.card(withId: cardID)
    }

    var body: some View {
        Group {
            if let card = card {
                cardContentView(card)
            } else {
                // 카드를 찾을 수 없는 경우
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("카드를 찾을 수 없습니다")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button("돌아가기") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemBackground))
        .onAppear {
            if let card = card {
                CardManager.shared.markCardAsViewed(card)
            }
        }
    }
    
    @ViewBuilder
    private func cardContentView(_ card: Card) -> some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {

                    Spacer().frame(height: 60)

                    // 썸네일 이미지
                    Image(card.thumbnailName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: calculateImageHeight(card))
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            selectedImage = card.thumbnailName
                        }

                    Spacer().frame(height: 24)

                    // 본문
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
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // 상세 정보
                        if !card.fields.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("상세 정보")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }

                                ForEach(Array(card.fields.keys.sorted()), id: \.self) { key in
                                    if let value = card.fields[key], !value.isEmpty {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text(key)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 80, alignment: .leading)
                                            Text(value)
                                                .font(.system(size: 14))
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            Divider()
                        }

                        // 태그
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("태그")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }

                            if card.tags.isEmpty {
                                Button {
                                    showAddTagSheet = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                        Text("태그 추가")
                                            .font(.system(size: 13))
                                    }
                                    .foregroundStyle(Color.brandAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.brandAccent.opacity(0.08))
                                    .clipShape(Capsule())
                                }

                            } else {

                                FlowLayout(spacing: 8) {

                                    ForEach(card.tags, id: \.self) { tag in
                                        HStack(spacing: 6) {
                                            Text("#\(tag)")
                                                .font(.system(size: 13))
                                                .fontWeight(.medium)

                                            Button {
                                                tagToDelete = tag
                                                showDeleteConfirm = true
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(Color.brandAccent.opacity(0.6))
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.brandAccent.opacity(0.08))
                                        .foregroundStyle(Color.brandAccent)
                                        .clipShape(Capsule())
                                    }

                                    Button {
                                        showAddTagSheet = true
                                    } label: {
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

            // 커스텀 네비
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text("상세 정보")
                        .font(.system(size: 17, weight: .semibold))

                    Spacer()

                    HStack(spacing: 12) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.caplogGrayDark)
                            .onTapGesture { showEditSheet = true }

                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.registerRed.opacity(0.75))
                            .onTapGesture { showCardDeleteConfirm = true }
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 44)
                .padding(.top, 8)
                .background(Color(.systemBackground))

                Spacer()
            }
        }

        // 전체 이미지 보기
        .fullScreenCover(isPresented: Binding(
            get: { selectedImage != nil },
            set: { if !$0 { selectedImage = nil } }
        )) {
            if let imageName = selectedImage {
                FullScreenImageView(imageName: imageName)
            }
        }

        // 태그 추가
        .sheet(isPresented: $showAddTagSheet, onDismiss: {
            // 태그 추가 후 자동으로 최신 데이터 반영됨
        }) {
            if let currentCard = self.card {
                AddTagSheet(currentTags: currentCard.tags) { newTag in
                    if !currentCard.tags.contains(newTag) {
                        var updatedCard = currentCard
                        updatedCard.tags.append(newTag)
                        Task {
                            await CardManager.shared.updateCard(updatedCard)
                        }
                    }
                }
            }
        }

        // 카드 수정 화면
        .sheet(isPresented: $showEditSheet, onDismiss: {
            // sheet 닫힐 때 자동으로 최신 데이터 반영됨
        }) {
            if let currentCard = self.card {
                CardEditSheet(card: currentCard) {
                    // onSave - 아무것도 안 해도 됨 (자동 갱신)
                }
            }
        }

        // 태그 삭제
        .alert("태그 삭제", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) { tagToDelete = nil }
            Button("삭제", role: .destructive) {
                if let tag = tagToDelete, let currentCard = self.card {
                    var updatedCard = currentCard
                    updatedCard.tags.removeAll { $0 == tag }
                    Task {
                        await CardManager.shared.updateCard(updatedCard)
                    }
                }
                tagToDelete = nil
            }
        } message: {
            if let tag = tagToDelete {
                Text("'\(tag)' 태그를 삭제하시겠습니까?")
            }
        }

        // 카드 삭제
        .alert("카드 삭제", isPresented: $showCardDeleteConfirm) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                if let currentCard = self.card {
                    Task {
                        await CardManager.shared.deleteCard(id: currentCard.id)
                        dismiss()
                    }
                }
            }
        } message: {
            if let currentCard = self.card {
                Text("'\(currentCard.title)' 카드를 삭제하시겠습니까?\n삭제된 카드는 복구할 수 없습니다.")
            }
        }
    }

    // MARK: - 이미지 높이
    private func calculateImageHeight(_ card: Card) -> CGFloat {
        let baseHeight: CGFloat = 220
        var contentHeight: CGFloat = 0
        contentHeight += 100
        if card.summary.count > 50 { contentHeight += 30 }
        contentHeight += CGFloat(card.fields.count) * 30
        let tagLines = ceil(Double(card.tags.count) / 3.0)
        contentHeight += CGFloat(tagLines) * 40
        let reduction = min(80, contentHeight / 8)
        return max(160, min(220, baseHeight - reduction))
    }
}
