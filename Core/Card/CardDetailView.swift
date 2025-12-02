import SwiftUI

/// 카드 상세 화면
struct CardDetailView: View {

    // ★ card를 로컬에서 관리 — 변경 즉시 반영 + 화면 재입장 시 유지
    @State private var localCard: Card
    @State private var editableTags: [String]

    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var selectedImage: String? = nil
    @State private var showAddTagSheet = false
    @State private var tagToDelete: String? = nil
    @State private var showDeleteConfirm = false
    @State private var showCardDeleteConfirm = false

    init(card: Card) {
        self._localCard = State(initialValue: card)
        self._editableTags = State(initialValue: card.tags)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {

                    Spacer().frame(height: 60)

                    // 썸네일 이미지
                    Image(localCard.thumbnailName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: calculateImageHeight())
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            selectedImage = localCard.thumbnailName
                        }

                    Spacer().frame(height: 24)

                    // 본문
                    VStack(alignment: .leading, spacing: 12) {

                        // 카테고리
                        HStack {
                            Text(localCard.category.emoji)
                                .font(.system(size: 20))
                            Text(localCard.category.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(localCard.subcategory)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }

                        // 제목
                        Text(localCard.title)
                            .font(.system(size: 24, weight: .bold))

                        // 요약
                        if !localCard.summary.isEmpty {
                            Text(localCard.summary)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // 상세 필드
                        if !localCard.fields.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(localCard.fields.keys.sorted()), id: \.self) { key in
                                    if let value = localCard.fields[key], !value.isEmpty {
                                        HStack(alignment: .top) {
                                            Text(key)
                                                .font(.system(size: 14, weight: .semibold))
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

                            if editableTags.isEmpty {
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

                                    ForEach(editableTags, id: \.self) { tag in
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

        .navigationBarHidden(true)
        .background(Color(.systemBackground))

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
        .sheet(isPresented: $showAddTagSheet) {
            AddTagSheet(currentTags: editableTags) { newTag in
                if !editableTags.contains(newTag) {
                    editableTags.append(newTag)
                    saveTagChanges()
                }
            }
        }

        // 카드 수정 화면
        .sheet(isPresented: $showEditSheet) {
            CardEditSheet(card: localCard) {
                refreshLocalCard()
            }
        }

        // 태그 삭제
        .alert("태그 삭제", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) { tagToDelete = nil }
            Button("삭제", role: .destructive) {
                if let tag = tagToDelete {
                    editableTags.removeAll { $0 == tag }
                    saveTagChanges()
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
                deleteCard()
            }
        } message: {
            Text("'\(localCard.title)' 카드를 삭제하시겠습니까?\n삭제된 카드는 복구할 수 없습니다.")
        }

        .onAppear {
            CardManager.shared.markCardAsViewed(localCard)
        }
    }

    // MARK: - 이미지 높이
    private func calculateImageHeight() -> CGFloat {
        let baseHeight: CGFloat = 220
        var contentHeight: CGFloat = 0
        contentHeight += 100
        if localCard.summary.count > 50 { contentHeight += 30 }
        contentHeight += CGFloat(localCard.fields.count) * 30
        let tagLines = ceil(Double(editableTags.count) / 3.0)
        contentHeight += CGFloat(tagLines) * 40
        let reduction = min(80, contentHeight / 8)
        return max(160, min(220, baseHeight - reduction))
    }

    // MARK: - 태그 저장
    private func saveTagChanges() {
        var updated = localCard
        updated.tags = editableTags

        Task {
            await CardManager.shared.updateCard(updated)

            if let newVersion = CardManager.shared.card(withId: updated.id) {
                await MainActor.run { localCard = newVersion }
            }
        }
    }

    // MARK: - 카드 수정 후 로컬 갱신
    private func refreshLocalCard() {
        if let newVersion = CardManager.shared.card(withId: localCard.id) {
            localCard = newVersion
        }
    }

    // MARK: - 카드 삭제
    private func deleteCard() {
        Task {
            await CardManager.shared.deleteCard(id: localCard.id)
            dismiss()
        }
    }
}
