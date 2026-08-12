import SwiftUI
import Combine

/// 회원가입/로그인 첫 화면 (Join / Log in 버튼)
struct Register1View: View {
    @ObservedObject var appState: AppState
    
    // OCR + GPT 상태 관리
    @State private var selectedImage: UIImage?
    @State private var recognizedText: [String] = []
    @State private var imageLabels: [ImageLabel] = []
    @State private var preprocessedImage: UIImage?
    @State private var gptResult: String?
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
                // 주 동작(회원가입)은 채움, 보조 동작(로그인)은 테두리형으로 위계를 둡니다.
                // 예전에는 주 동작이 가장 연한 색(#AABBBE)이라 위계가 뒤집혀 있었습니다.
                VStack(spacing: 12) {
                    NavigationLink(destination: Register2View(appState: appState)) {
                        Text("회원가입").authPrimaryButton()
                    }
                    NavigationLink(destination: Register3View(appState: appState)) {
                        Text("로그인").authSecondaryButton()
                    }
                }
                .padding(.horizontal, 24)

                // 약관 안내
                // 실제 동의는 가입 폼(Register2)의 필수 체크박스에서 받습니다.
                // "가입 시 동의하게 됩니다"라고 쓰면 그 체크박스와 말이 어긋납니다.
                // 색은 brandTextSub(#6B6B6B)이면 그라데이션 위쪽에서 2.13:1까지
                // 떨어지므로, 어디에 놓여도 견디는 본문색(최소 6.05:1)을 씁니다.
                Text("가입 단계에서 이용약관과 개인정보처리방침 동의가 필요합니다.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.brandTextMain)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 원래의 틸→크림 그라데이션을 유지합니다.
            .background(AuthBackground())
            .toolbar(.hidden, for: .navigationBar)
            
            // ✅ OCRResultView로 이동
            .navigationDestination(isPresented: $navigateToResult) {
                OCRResultView(
                    image: selectedImage,
                    recognizedText: recognizedText,
                    gptResult: gptResult ?? "GPT 결과 없음",
                    imageLabels: imageLabels.isEmpty ? nil : imageLabels
                )
            }
        }
        
        // ✅ PhotoPicker 연결 (새 버전)
        .fullScreenCover(isPresented: $showPhotoPicker) {
            PhotoPickerWrapperView(
                isPresented: $showPhotoPicker,
                selectedImage: $selectedImage,
                recognizedText: $recognizedText,
                imageLabels: $imageLabels,
                gptResult: $gptResult,
                navigateToResult: $navigateToResult
            )
        }
    }
}

// ✅ PhotoPicker를 감싸는 헬퍼 뷰
struct PhotoPickerWrapperView: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Binding var recognizedText: [String]
    @Binding var imageLabels: [ImageLabel]
    @Binding var gptResult: String?
    @Binding var navigateToResult: Bool
    
    @State private var isProcessing = false
    @State private var resultCard: Card?
    @State private var processingResult: ProcessingResult?
    @State private var errorMessage: String?
    
    var body: some View {
        PhotoPicker(
            isProcessing: $isProcessing,
            resultCard: $resultCard,
            processingResult: $processingResult,
            errorMessage: $errorMessage
        ) { result in
            // ✅ ProcessingResult에서 모든 데이터 추출
            selectedImage = result.preprocessedImage
            recognizedText = result.ocrText
            imageLabels = result.imageLabels
            gptResult = "카테고리: \(result.card.category.rawValue) - \(result.card.subcategory)\n제목: \(result.card.title)\n요약: \(result.card.summary)"
            
            navigateToResult = true
            isPresented = false
        }
    }
}
