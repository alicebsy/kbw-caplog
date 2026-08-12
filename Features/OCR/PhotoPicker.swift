import SwiftUI
import PhotosUI

/// 통합 파이프라인을 사용하는 PhotoPicker (온디바이스 분석 -> GPT -> Card 자동 생성)
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var isProcessing: Bool
    @Binding var resultCard: Card?
    @Binding var processingResult: ProcessingResult?  // ✅ 원본 데이터 함께 저장
    @Binding var errorMessage: String?
    
    var onProcessingComplete: ((ProcessingResult) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        let processingService = ScreenshotProcessingService()
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }
            
            DispatchQueue.main.async {
                self.parent.isProcessing = true
                self.parent.errorMessage = nil
            }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self = self,
                      let uiImage = image as? UIImage else {
                    DispatchQueue.main.async {
                        self?.parent.isProcessing = false
                        self?.parent.errorMessage = "이미지 로드 실패"
                    }
                    return
                }
                
                // 🚀 통합 파이프라인 실행
                self.processingService.processScreenshot(image: uiImage) { result in
                    DispatchQueue.main.async {
                        self.parent.isProcessing = false
                        
                        switch result {
                        case .success(let processingResult):
                            print("✅ 처리 완료: \(processingResult.card.title)")
                            print("OCR 라인: \(processingResult.ocrText.count)개")
                            print("온디바이스 이미지 레이블: \(processingResult.imageLabels.count)개")
                            
                            self.parent.resultCard = processingResult.card
                            self.parent.processingResult = processingResult
                            self.parent.onProcessingComplete?(processingResult)
                            
                        case .failure(let error):
                            print("❌ 처리 실패: \(error.localizedDescription)")
                            self.parent.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 사용 예시 View
struct ScreenshotUploadView: View {
    @State private var showPhotoPicker = false
    @State private var isProcessing = false
    @State private var resultCard: Card?
    @State private var processingResult: ProcessingResult?
    @State private var errorMessage: String?
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("스크린샷 업로드")
                .font(.title)
                .bold()
            
            if isProcessing {
                ProgressView("처리 중...")
                    .progressViewStyle(.circular)
                Text("기기 내 OCR·이미지 분석 → GPT 분류 → 카드 생성")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("사진 선택", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if let card = resultCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("카드 생성 완료", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.pointTeal)
                    
                    Text(card.title)
                        .font(.title3)
                        .bold()
                    
                    Text(card.summary)
                        .font(.body)
                        .foregroundColor(Color.brandTextSub)
                    
                    HStack {
                        Image(systemName: card.category.symbolName)
                            .foregroundStyle(card.category.color)
                            .accessibilityHidden(true)
                        Text(card.subcategory)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(card.category.color.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    if !card.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(card.tags.prefix(5), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.homeGreenTint)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(Color.homeGreenTint.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    Button("상세 보기") {
                        showResult = true
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(
                isProcessing: $isProcessing,
                resultCard: $resultCard,
                processingResult: $processingResult,
                errorMessage: $errorMessage
            ) { result in
                print("🔄 처리 완료: \(result.card.title)")
                print("OCR 텍스트: \(result.ocrText.count)개 라인")
                print("온디바이스 이미지 레이블: \(result.imageLabels.count)개")
            }
        }
        .sheet(isPresented: $showResult) {
            if let card = resultCard {
                CardDetailView(card: card)
            }
        }
    }
}

#Preview {
    ScreenshotUploadView()
}
