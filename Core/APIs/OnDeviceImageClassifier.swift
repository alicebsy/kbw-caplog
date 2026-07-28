import Foundation
import UIKit
import Vision

/// 원본 이미지를 외부로 전송하지 않고 Apple Vision으로 분류합니다.
final class OnDeviceImageClassifier {
    func classify(
        from image: UIImage,
        completion: @escaping (Result<[ImageLabel], Error>) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(.failure(ImageClassificationError.imageConversionFailed))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
                let labels = (request.results ?? [])
                    .filter { $0.confidence >= 0.2 }
                    .prefix(10)
                    .map {
                        ImageLabel(
                            description: $0.identifier,
                            confidence: Double($0.confidence)
                        )
                    }
                completion(.success(Array(labels)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

struct ImageLabel: Codable, Identifiable {
    let description: String
    let confidence: Double

    var id: String { "\(description)_\(confidence)" }

    var confidencePercentage: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

enum ImageClassificationError: LocalizedError {
    case imageConversionFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "이미지 변환에 실패했습니다."
        }
    }
}
