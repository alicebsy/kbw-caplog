import SwiftUI

/// 카드 상세 화면
struct CardDetailView: View {
    let card: Card
    
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showEditSheet = false
    @State private var selectedImage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 썸네일 이미지
                Image(card.thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
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
                    
                    // 태그
                    if !card.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("태그")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(card.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.brandAccent.opacity(0.15))
                                        .foregroundStyle(Color.brandAccent)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    // 날짜 정보
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("생성일")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Text(card.dateString)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        }
                        
                        HStack {
                            Text("수정일")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                            Text(formatDate(card.updatedAt))
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // 스크린샷 갤러리
                if !card.screenshotURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("스크린샷")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(card.screenshotURLs, id: \.self) { imageName in
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .onTapGesture {
                                            selectedImage = imageName
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.top, 20)
        }
        .navigationTitle("상세 정보")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showShareSheet = true }) {
                        Label("공유", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { showEditSheet = true }) {
                        Label("수정", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        // 전체 화면 이미지 뷰
        .fullScreenCover(isPresented: Binding(
            get: { selectedImage != nil },
            set: { if !$0 { selectedImage = nil } }
        )) {
            if let imageName = selectedImage {
                FullScreenImageView(imageName: imageName)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
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
