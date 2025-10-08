//
//  TagEditSheet.swift
//  caplog
//
//  Created by user on 10/9/25.
//


import SwiftUI

struct TagEditSheet: View {
    let content: Content
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tags: String

    init(content: Content, onSave: @escaping (String) -> Void) {
        self.content = content
        self.onSave = onSave
        _tags = State(initialValue: content.tags)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("태그") {
                    TextField("#태그를 쉼표 또는 공백으로 입력", text: $tags)
                        .textInputAutocapitalization(.never)
                }
                Section {
                    Button("저장") {
                        onSave(tags.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
            }
            .navigationTitle("태그 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}
