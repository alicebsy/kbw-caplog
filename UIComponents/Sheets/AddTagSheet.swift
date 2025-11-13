import SwiftUI

// MARK: - Add Tag Sheet (개선된 버전)

struct AddTagSheet: View {
    let currentTags: [String]
    let onAdd: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var newTagText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 여백
                Spacer()
                    .frame(height: 40)
                
                // 제목
                Text("새 태그 추가")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                    .frame(height: 32)
                
                // 입력 필드 (Form 스타일)
                VStack(spacing: 0) {
                    TextField("태그 입력", text: $newTagText)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            addTag()
                        }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 24)
                
                // 추가 버튼
                Button(action: addTag) {
                    Text("추가")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(newTagText.isEmpty ? .secondary : Color.myPageActionBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            newTagText.isEmpty 
                                ? Color(.systemGray5)
                                : Color.myPageActionBlueBg
                        )
                        .cornerRadius(12)
                }
                .disabled(newTagText.isEmpty)
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 20)
                
                // 안내 문구
                Text("중복된 태그는 추가할 수 없습니다.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !currentTags.contains(trimmed) else { return }
        
        onAdd(trimmed)
        dismiss()
    }
}
