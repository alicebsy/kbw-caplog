//
//  MyPageAccountSection.swift
//  Caplog
//
//  Created by Caplog Team.
//

import SwiftUI

struct MyPageAccountSection: View {
    
    @Binding var name: String
    let userId: String
    let email: String
    
    var onChangePassword: () -> Void
    var onChangeProfileImage: () -> Void    // ✅ 추가
    var onSave: () -> Void
    var isSaveEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - 섹션 제목
            Text("계정 정보")
                .font(.system(size: 20, weight: .semibold))
                .padding(.bottom, 4)
            
            // MARK: - 이름
            LabeledRow(label: "이름") {
                TextField("이름을 입력하세요", text: $name)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            
            // MARK: - 아이디
            LabeledRow(label: "아이디") {
                Text(userId)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            
            // MARK: - 이메일
            LabeledRow(label: "이메일") {
                Text(email)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            
            // MARK: - 비밀번호 변경
            LabeledRow(label: "비밀번호") {
                Button(action: onChangePassword) {
                    HStack {
                        Text("변경")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                }
            }
            
            // MARK: - 🔥 프로필 사진 변경
            LabeledRow(label: "프로필 사진") {
                Button(action: onChangeProfileImage) {
                    HStack {
                        Text("변경")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                }
            }
            
            // MARK: - 저장 버튼
            Button(action: onSave) {
                Text("저장하기")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSaveEnabled ? Color.primary.opacity(0.9) : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!isSaveEnabled)
            .padding(.top, 12)
            
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    MyPageAccountSection(
        name: .constant("강배우"),
        userId: "ewhakbw",
        email: "ewhakbw@gmail.com",
        onChangePassword: {},
        onChangeProfileImage: {},   // Preview용
        onSave: {},
        isSaveEnabled: true
    )
}
