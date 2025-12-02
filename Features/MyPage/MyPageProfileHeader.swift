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
            // 프로필 이미지 + 카메라 버튼
            ZStack(alignment: .bottomTrailing) {
                // 프로필 이미지
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(Color.caplogGrayMedium, Color.caplogGrayLight)
                }

                // 카메라 버튼 (검은 카메라 아이콘만)
                Button {
                    if profileImage != nil {
                        // 사진이 있을 때는 옵션 알림 표시
                        showPhotoAlert = true
                    } else {
                        // 아직 사진이 없으면 바로 앨범 열기
                        showImagePicker = true
                    }
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(4)
                }
                .offset(x: 2, y: 2)
            }

            // 이름 + 비밀번호 변경 버튼
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(displayName.isEmpty ? "강배우" : displayName) 님")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }

                Spacer(minLength: 8)

                CapsuleButton(
                    title: "비밀번호 변경",
                    action: onChangePassword,
                    tint: .primary,
                    fill: .white,
                    fullWidth: false,
                    isEnabled: true,
                    verticalPadding: 6,
                    fontSize: 13
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
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
