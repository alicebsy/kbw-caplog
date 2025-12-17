//
//  ScreenshotDebugView.swift
//  Caplog
//
//  OCR, Google Vision, GPT-4 처리 결과 확인용 디버그 뷰
//

import SwiftUI
import PhotosUI

struct ScreenshotDebugView: View {
    @State private var showPhotoPicker = false
    @State private var isProcessing = false
    @State private var selectedImage: UIImage?
    @State private var processingResult: ProcessingResult?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 📸 이미지 선택 버튼
                    if selectedImage == nil {
                        Button {
                            showPhotoPicker = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)
                                Text("스크린샷 선택")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // 🖼️ 선택된 이미지 표시
                    if let image = selectedImage {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("선택된 이미지")
                                    .font(.headline)
                                Spacer()
                                Button("다시 선택") {
                                    selectedImage = nil
                                    processingResult = nil
                                    errorMessage = nil
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                        }
                    }
                    
                    // ⏳ 처리 중 표시
                    if isProcessing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("처리 중...")
                                .font(.headline)
                            Text("OCR → Google Vision → GPT-4 분류")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    
                    // ❌ 에러 메시지
                    if let error = errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("에러 발생", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // ✅ 처리 결과 표시
                    if let result = processingResult {
                        ResultSections(result: result)
                    }
                }
                .padding()
            }
            .navigationTitle("스크린샷 선택")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPhotoPicker) {
                DebugPhotoPicker(
                    isProcessing: $isProcessing,
                    selectedImage: $selectedImage,
                    processingResult: $processingResult,
                    errorMessage: $errorMessage
                )
            }
        }
    }
}

// MARK: - 결과 섹션들
struct ResultSections: View {
    let result: ProcessingResult
    
    var body: some View {
        VStack(spacing: 16) {
            // 1️⃣ GPT-4 분류 결과
            ResultSection(
                title: "📦 GPT-4 분류 결과",
                color: .yellow
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ResultRow(label: "제목", value: result.card.title)
                    ResultRow(label: "카테고리", value: result.card.category.rawValue)
                    ResultRow(label: "서브카테고리", value: result.card.subcategory)
                    ResultRow(label: "요약", value: result.card.summary)
                    
                    if !result.card.tags.isEmpty {
                        HStack {
                            Text("태그:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(result.card.tags.map { "#\($0)" }.joined(separator: " "))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // 2️⃣ VisionKit OCR 결과
            ResultSection(
                title: "📄 VisionKit OCR 결과 (\(result.ocrText.count)개 라인)",
                color: .blue
            ) {
                if result.ocrText.isEmpty {
                    Text("인식된 텍스트가 없습니다")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(result.ocrText.enumerated()), id: \.offset) { index, line in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                Text(line)
                                    .font(.body)
                                    .textSelection(.enabled)
                                Spacer()
                            }
                        }
                    }
                }
            }
            
            // 3️⃣ Google Vision 결과
            ResultSection(
                title: "🎯 Google Vision 레이블 (\(result.googleVisionLabels.count)개)",
                color: .green
            ) {
                if result.googleVisionLabels.isEmpty {
                    Text("탐지된 레이블이 없습니다")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(result.googleVisionLabels, id: \.description) { label in
                            HStack {
                                Text(label.description)
                                    .font(.body)
                                Spacer()
                                Text(label.confidencePercentage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            
            // 4️⃣ 메타데이터
            ResultSection(
                title: "ℹ️ 메타데이터",
                color: .gray
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ResultRow(label: "카드 ID", value: result.card.id.uuidString)
                    ResultRow(label: "생성 시간", value: formatDate(result.card.createdAt))
                    ResultRow(label: "스크린샷 수", value: "\(result.card.screenshotURLs.count)개")
                    if !result.card.tags.isEmpty {
                        ResultRow(label: "태그 수", value: "\(result.card.tags.count)개")
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - 결과 섹션 컴포넌트
struct ResultSection<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - 결과 행 컴포넌트
struct ResultRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}

// MARK: - 디버그용 PhotoPicker
struct DebugPhotoPicker: UIViewControllerRepresentable {
    @Binding var isProcessing: Bool
    @Binding var selectedImage: UIImage?
    @Binding var processingResult: ProcessingResult?
    @Binding var errorMessage: String?
    
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
        let parent: DebugPhotoPicker
        let processingService = ScreenshotProcessingService()
        
        init(_ parent: DebugPhotoPicker) {
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
                self.parent.processingResult = nil
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
                
                DispatchQueue.main.async {
                    self.parent.selectedImage = uiImage
                }
                
                // 🚀 통합 파이프라인 실행
                self.processingService.processScreenshot(image: uiImage) { result in
                    DispatchQueue.main.async {
                        self.parent.isProcessing = false
                        
                        switch result {
                        case .success(let processingResult):
                            print("✅ 디버그 처리 완료")
                            self.parent.processingResult = processingResult
                            
                        case .failure(let error):
                            print("❌ 디버그 처리 실패: \(error.localizedDescription)")
                            self.parent.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScreenshotDebugView()
}
