import SwiftUI
import PhotosUI
import Vision

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var recognizedText: [String]
    @Binding var preprocessedImage: UIImage?
    @Binding var gptResult: String?
    @Binding var apiUsage: String?

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

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let uiImage = image as? UIImage else { return }
                DispatchQueue.main.async {
                    self.parent.selectedImage = uiImage
                    if let processed = self.preprocessImage(uiImage) {
                        self.parent.preprocessedImage = processed
                        self.recognizeText(from: processed)
                    }
                }
            }
        }

        private func preprocessImage(_ uiImage: UIImage) -> UIImage? {
            guard let ciImage = CIImage(image: uiImage) else { return nil }
            let enhanced = ciImage
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 0.0,
                    kCIInputContrastKey: 1.4
                ])
                .applyingFilter("CIExposureAdjust", parameters: [
                    kCIInputEVKey: 0.7
                ])
                .applyingFilter("CILanczosScaleTransform", parameters: [
                    kCIInputScaleKey: 1.5,
                    kCIInputAspectRatioKey: 1.0
                ])
            let context = CIContext()
            guard let cgImage = context.createCGImage(enhanced, from: enhanced.extent) else { return nil }
            return UIImage(cgImage: cgImage)
        }

        private func recognizeText(from image: UIImage) {
            guard let cgImage = image.cgImage else { return }

            let request = VNRecognizeTextRequest { request, _ in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let allLines = lines.joined(separator: "\n")
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                let merged: [String] = allLines.flatMap { line -> [String] in
                    let delimiters = [". ", "? ", "! "]
                    for delimiter in delimiters {
                        if line.contains(delimiter) {
                            return line.components(separatedBy: delimiter).map { $0 + delimiter.trimmingCharacters(in: .whitespaces) }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        }
                    }
                    return [line]
                }

                DispatchQueue.main.async {
                    self.parent.recognizedText = merged
                    self.callGPT(with: merged.joined(separator: "\n"))
                }
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }

        private func callGPT(with text: String) {
            guard let apiKey = Bundle.main.infoDictionary?["GPT_API_KEY"] as? String else {
                print("❌ GPT API 키를 불러올 수 없습니다.")
                return
            }

            let prompt = makePrompt(from: text)
            classifyTextWithGPT_stable(prompt: prompt, apiKey: apiKey) { result, usage in
                DispatchQueue.main.async {
                    print("📨 GPT Raw Response:\n\(result)") // ✅ 디버깅용 출력
                    self.parent.gptResult = result
                    self.parent.apiUsage = usage
                }
            }
        }

        // ✅ GPT 분류 요청용 프롬프트 생성 함수 수정
        private func makePrompt(from text: String) -> String {
            guard let url = Bundle.main.url(forResource: "categories", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode(TabCategoryMap.self, from: data) else {
                return "❌ 분류 기준 로딩 실패"
            }

            var formatted = ""
            for (tab, categories) in decoded {
                formatted += "=== \(tab) ===\n"
                let sortedKeys = categories.keys.sorted()
                for key in sortedKeys {
                    if let group = categories[key] {
                        formatted += "\(key). \(group.name)\n"
                        let sortedChildren = group.children.keys.sorted()
                        for subKey in sortedChildren {
                            if let label = group.children[subKey] {
                                formatted += "  - [\(subKey)] \(label)\n"
                            }
                        }
                        formatted += "\n"
                    }
                }
            }

            return """
            다음은 사용자가 스크린샷에서 추출한 텍스트입니다:

            ""
            \(text)
            ""
            
            아래 분류 기준에 따라 가장 적절한 카테고리를 골라줘.
            포맷은 [1.3] 장소 - 취미 (영화, 공연, 액티비티) 식으로 작성해.

            만약 분류 결과가 [1.1] 맛집 또는 [1.2] 카페라면, 아래 항목도 함께 추출해줘.

            예시 출력:
            카테고리: [1.1] 맛집
            1. 식당 이름: 화랑초밥
            2. 지역: 송파구
            3. 주소: 서울시 송파구 법원로11길 25
            4. 위치: 법조타운 근처
            5. 메뉴: 초밥, 회, 우동

            \(formatted)
            """
        }
    }
}
