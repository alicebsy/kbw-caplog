//
//  ChangePasswordSheet.swift
//  Caplog
//
//  Created by user on 10/15/25.
//


import SwiftUI

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// 호출 측에서 넘겨주는 비밀번호 변경 실행기
    var onSubmit: (_ current: String, _ new: String) async throws -> Void

    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var isSubmitting = false
    @State private var error: String? = nil
    @State private var showSuccess = false

    private var isValid: Bool {
        guard !current.isEmpty, new.count >= 8, new == confirm else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("현재 비밀번호") {
                    SecureField("현재 비밀번호", text: $current)
                        .textContentType(.password)
                }
                Section("새 비밀번호") {
                    SecureField("새 비밀번호 (8자 이상)", text: $new)
                        .textContentType(.newPassword)
                    SecureField("새 비밀번호 확인", text: $confirm)
                        .textContentType(.newPassword)
                    if !confirm.isEmpty && new != confirm {
                        Text("비밀번호가 일치하지 않습니다.")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
                if let error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .disabled(isSubmitting)
            .navigationTitle("비밀번호 변경")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "처리중…" : "변경") {
                        Task { await submit() }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .alert("변경 완료", isPresented: $showSuccess) {
                Button("확인") { dismiss() }
            } message: {
                Text("비밀번호가 성공적으로 변경되었습니다.")
            }
        }
    }

    private func submit() async {
        error = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await onSubmit(current, new)
            showSuccess = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}