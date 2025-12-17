import SwiftUI

struct OCRResultView: View {
    let image: UIImage?
    let recognizedText: [String]  // VisionKit OCR 결과
    let gptResult: String?
    let googleVisionLabels: [VisionLabel]?  // Google Cloud Vision 레이블 탐지 결과

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ✅ 이미지 표시
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }

                // ✅ 1️⃣ GPT-4 분류 결과 (노란색)
                if let result = gptResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📦 GPT-4 분류 결과")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(result)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                }

                // ✅ 2️⃣ VisionKit OCR 결과 (회색)
                VStack(alignment: .leading, spacing: 8) {
                    Text("📄 VisionKit OCR 결과")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    if recognizedText.isEmpty {
                        Text("인식된 텍스트가 없습니다.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .modifier(DetailItemStyle())
                    } else {
                        let merged = mergeNumberedLines(from: recognizedText)
                        Text(merged.joined(separator: "\n"))
                            .modifier(DetailItemStyle())
                    }
                }
                .frame(maxWidth: .infinity)

                // ✅ 3️⃣ Google Cloud Vision 결과 (회색)
                if let labels = googleVisionLabels, !labels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🎯 Google Cloud Vision (객체/개념 탐지)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(labels, id: \.description) { label in
                                HStack {
                                    Text(label.description)
                                        .font(.body)
                                    Spacer()
                                    Text(label.confidencePercentage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .modifier(DetailItemStyle())
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🎯 Google Cloud Vision (객체/개념 탐지)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("탐지된 객체/개념이 없습니다.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .modifier(DetailItemStyle())
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("스크린샷 정보")
        .navigationBarTitleDisplayMode(.inline)
    }

    func mergeNumberedLines(from lines: [String]) -> [String] {
        var result: [String] = []
        var i = 0
        let pattern = "^\\d+[\\.\\)]?$"

        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if let _ = trimmed.range(of: pattern, options: .regularExpression), i + 1 < lines.count {
                result.append("\(trimmed) \(lines[i + 1])")
                i += 2
            } else {
                result.append(lines[i])
                i += 1
            }
        }
        return result
    }
}

struct DetailItemStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}
