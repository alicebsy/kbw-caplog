import SwiftUI

struct OCRResultView: View {
    let image: UIImage?
    let recognizedText: [String]
    let gptResult: String?
    let apiUsage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ✅ 이미지 표시
                if let image = image {
                    Text("Preprocessed Image for OCR")
                        .font(.headline)
                        .padding(.top, 8)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }

                // ✅ GPT 분류 결과
                if let result = gptResult {
                    Text("📦 GPT 분류 결과")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.top, 8)

                    Text(result)
                        .padding()
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(10)

                    if result.hasPrefix("[1.1]") || result.hasPrefix("[1.2]") {
                        detailSection(title: "1. 식당 이름", key: "식당 이름")
                        detailSection(title: "2. 지역", key: "지역")
                        detailSection(title: "3. 주소", key: "주소")
                        detailSection(title: "4. 위치", key: "위치")
                        detailSection(title: "5. 메뉴", key: "메뉴")
                    } else if result.hasPrefix("[3.3]") {
                        detailSection(title: "1. 제품 이름", key: "이름")
                        detailSection(title: "2. 판매자", key: "판매자")
                        detailSection(title: "3. 가격", key: "가격")
                        detailSection(title: "4. 원산지", key: "원산지")
                        detailSection(title: "5. 중량", key: "중량")
                        detailSection(title: "6. 인증", key: "인증")
                        detailSection(title: "7. 만족도", key: "만족")
                        detailSection(title: "8. 옵션", key: "옵션")
                    } else {
                        let merged = mergeNumberedLines(from: recognizedText)
                        ForEach(Array(merged.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .modifier(DetailItemStyle())
                        }
                    }
                } else {
                    let merged = mergeNumberedLines(from: recognizedText)
                    ForEach(Array(merged.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .modifier(DetailItemStyle())
                    }
                }

                if let usage = apiUsage {
                    Text("🧾 API 사용량: \(usage)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                }
            }
            .padding()
        }
        .navigationTitle("OCR + GPT 결과")
        .navigationBarTitleDisplayMode(.inline)
    }

    func detailSection(title: String, key: String) -> some View {
        Text("\(title) \(extractDetail(from: recognizedText, key: key))")
            .modifier(DetailItemStyle())
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

    func extractDetail(from lines: [String], key: String) -> String {
        for line in lines {
            if line.contains(key) {
                return line
            }
        }
        return ""
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
