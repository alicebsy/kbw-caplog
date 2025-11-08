import SwiftUI
import Combine

struct Register1View: View {
    @Binding var isLoggedIn: Bool
    
    // ✅ OCR + GPT 상태 관리
    @State private var selectedImage: UIImage?
    @State private var recognizedText: [String] = []
    @State private var preprocessedImage: UIImage?
    @State private var gptResult: String?
    @State private var apiUsage: String?
    @State private var showPhotoPicker = false
    @State private var navigateToResult = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // 로고 + 앱명
                VStack(spacing: 16) {
                    Image("caplog_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                }
                
                // Join / Log in
                VStack(spacing: 16) {
                    NavigationLink(destination: Register2View()) {
                        Text("Join")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 343, height: 49)
                            .background(Color.joinButton)
                            .cornerRadius(16)
                    }
                    NavigationLink(destination: Register3View()) {
                        Text("Log in")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 343, height: 49)
                            .background(Color.loginButton)
                            .cornerRadius(16)
                    }
                }
                
                // 약관 안내
                Text("By joining Caplog, you agreed to\nour Terms of service and Privacy policy.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // ✅ 임시 버튼 섹션 (기존 그대로 유지)
                VStack(spacing: 12) {
                    NavigationLink(destination: Register4_1View()) {
                        Text("임시 레지스터4-1")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 40)
                            .background(Color.yellow)
                            .cornerRadius(10)
                    }
                    NavigationLink(destination: HomeView()) {
                        Text("임시 홈")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 40)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    NavigationLink(destination: MyPageView()) {
                        Text("임시 마이페이지")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 40)
                            .background(Color.purple)
                            .cornerRadius(10)
                    }

                    // ✅ 스크린샷 업로드 버튼
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Text("📸 스크린샷 업로드 (OCR + GPT 테스트)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 40)
                            .background(Color.homeGreen)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.brandGradientTop, .brandGradientBottom]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar(.hidden, for: .navigationBar)
            
            // ✅ OCRResultView로 이동
            .navigationDestination(isPresented: $navigateToResult) {
                OCRResultView(
                    image: selectedImage,
                    recognizedText: recognizedText,
                    gptResult: gptResult ?? "GPT 결과 없음 ❌",
                    apiUsage: apiUsage
                )
            }
        }
        
        // ✅ PhotoPicker 연결
        .fullScreenCover(isPresented: $showPhotoPicker) {
            PhotoPicker(
                selectedImage: $selectedImage,
                recognizedText: $recognizedText,
                preprocessedImage: $preprocessedImage,
                gptResult: $gptResult,
                apiUsage: $apiUsage
            )
        }
        
        // ✅ OCR 결과가 생기면 자동 이동 (GPT 결과 없어도)
        .onChange(of: recognizedText) { newText in
            if !newText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showPhotoPicker = false
                    navigateToResult = true
                }
            }
        }
    }
}
