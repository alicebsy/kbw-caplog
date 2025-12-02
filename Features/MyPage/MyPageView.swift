//
//  MyPageView.swift
//  Caplog
//
//  Created by Caplog Team.
//

import SwiftUI

struct MyPageView: View {
    @StateObject private var vm = MyPageViewModel()
    
    @State private var showPasswordSheet = false
    @State private var showProfileImageSheet = false   // ✅ 추가
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 헤더
            MyPageProfileHeader(
                displayName: vm.name,
                email: vm.email,
                profileImageName: vm.profileImageName   // ✅ 추가
            )
            .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - 계정 정보 변경 섹션
                    MyPageAccountSection(
                        name: $vm.name,
                        userId: vm.userId,
                        email: vm.email,
                        
                        onChangePassword: { 
                            showPasswordSheet = true 
                        },
                        
                        // 🔥 프로필 사진 변경 버튼
                        onChangeProfileImage: { 
                            showProfileImageSheet = true 
                        },
                        
                        onSave: {
                            Task { await vm.saveProfile() }
                        },
                        isSaveEnabled: vm.canSaveProfile
                    )
                    
                    // MARK: - 기타 설정 영역 (기존 그대로)
                    MyPageSettingsSection()
                    
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        
        
        // MARK: - 비밀번호 변경 시트
        .sheet(isPresented: $showPasswordSheet) {
            PasswordChangeView()
                .presentationDetents([.height(420)])
        }
        
        
        // MARK: - 프로필 사진 변경 시트
        .sheet(isPresented: $showProfileImageSheet) {
            VStack(spacing: 20) {
                Text("프로필 이미지 선택")
                    .font(.headline)
                    .padding(.top, 16)
                
                // 원하는 아바타 이름을 네 Asset과 맞게 조정 가능
                let avatarOptions = ["avatar_default", "avatar1", "avatar2", "avatar3"]
                
                HStack(spacing: 20) {
                    ForEach(avatarOptions, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .onTapGesture {
                                vm.profileImageName = name
                                Task { await vm.saveProfile() }
                                showProfileImageSheet = false
                            }
                    }
                }
                .padding(.top, 12)
                
                Button("닫기") {
                    showProfileImageSheet = false
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .presentationDetents([.height(300)])
        }
    }
}

#Preview {
    MyPageView()
}
