//
//  TagEditSheet.swift
//  caplog
//
//  Created by user on 10/9/25.
//


import SwiftUI

struct TagEditSheet: View {
    let card: Card
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tags: String

    init(card: Card, onSave: @escaping (String) -> Void) {
        self.card = card
        self.onSave = onSave
        _tags = State(initialValue: card.tagsString)
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
