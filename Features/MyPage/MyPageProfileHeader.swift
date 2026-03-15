import SwiftUI
import PhotosUI

struct MyPageProfileHeader: View {
    let displayName: String
    let email: String
    @Binding var profileImage: UIImage?
    let onImageSelected: (UIImage?) -> Void
    let onChangePassword: () -> Void   // 비밀번호 변경 액션

    @State private var showImagePicker = false
    @State private var showPhotoAlert = false
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(uiColor: .systemGray5), lineWidth: 1))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(Color.myPageSectionGreen.opacity(0.3), Color(uiColor: .systemGray6))
                }
                Button {
                    if profileImage != nil { showPhotoAlert = true }
                    else { showImagePicker = true }
                } label: {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                        .background(Circle().fill(Color.myPageSectionGreen))
                }
                .offset(x: 2, y: 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName.isEmpty ? "프로필" : displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Button(action: onChangePassword) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 12))
                        Text("비밀번호 변경")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color.myPageActionBlue)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        // 사진 선택용 PhotosPicker
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedItem,
            matching: .images
        )
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = image
                        onImageSelected(image)
                    }
                }
                selectedItem = nil
            }
        }
        // 🔔 가운데 뜨는 시스템 Alert 스타일
        .alert("프로필 사진", isPresented: $showPhotoAlert) {
            Button("사진 변경") {
                showImagePicker = true
            }
            Button("기본 이미지로 변경") {
                profileImage = nil
                onImageSelected(nil)
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("프로필 사진을 변경하시겠습니까?")
        }
    }
}
