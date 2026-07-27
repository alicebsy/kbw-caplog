import Foundation
import UIKit

/// Google Vision 요청을 인증된 Caplog 백엔드를 통해 수행합니다.
final class GoogleVisionService {
    private static let maxImageBytes = 10 * 1024 * 1024

    func extractText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        request(path: "ai/vision/text", image: image) { (result: Result<VisionTextResponse, Error>) in
            completion(result.map(\.text))
        }
    }

    func extractText(from image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            extractText(from: image) { result in
                continuation.resume(with: result)
            }
        }
    }

    func detectLabels(
        from image: UIImage,
        completion: @escaping (Result<[VisionLabel], Error>) -> Void
    ) {
        request(path: "ai/vision/labels", image: image) { (result: Result<VisionLabelsResponse, Error>) in
            completion(result.map(\.labels))
        }
    }

    func detectLabels(from image: UIImage) async throws -> [VisionLabel] {
        try await withCheckedThrowingContinuation { continuation in
            detectLabels(from: image) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func request<Response: Decodable>(
        path: String,
        image: UIImage,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        guard let token = SessionStore.readJWT(), !token.isEmpty else {
            completion(.failure(VisionError.unauthorized))
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(VisionError.imageConversionFailed))
            return
        }
        guard imageData.count <= Self.maxImageBytes else {
            completion(.failure(VisionError.imageTooLarge))
            return
        }

        var url = APIConfig.baseURL
        url.append(path: APIConfig.apiPrefix)
        url.append(path: path)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(
                VisionImageRequest(imageBase64: imageData.base64EncodedString())
            )
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(VisionError.invalidResponse))
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                if http.statusCode == 401 {
                    completion(.failure(VisionError.unauthorized))
                } else {
                    completion(.failure(VisionError.apiError(http.statusCode)))
                }
                return
            }
            guard let data else {
                completion(.failure(VisionError.noData))
                return
            }

            do {
                completion(.success(try JSONDecoder().decode(Response.self, from: data)))
            } catch {
                completion(.failure(VisionError.parsingFailed))
            }
        }.resume()
    }
}

private struct VisionImageRequest: Encodable {
    let imageBase64: String
}

private struct VisionTextResponse: Decodable {
    let text: String
}

private struct VisionLabelsResponse: Decodable {
    let labels: [VisionLabel]
}

struct VisionLabel: Codable, Identifiable {
    let description: String
    let confidence: Double

    var id: String { "\(description)_\(confidence)" }

    var confidencePercentage: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

enum VisionError: LocalizedError {
    case imageConversionFailed
    case imageTooLarge
    case unauthorized
    case invalidResponse
    case noData
    case parsingFailed
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "이미지 변환에 실패했습니다."
        case .imageTooLarge:
            return "이미지는 최대 10MB까지 전송할 수 있습니다."
        case .unauthorized:
            return "Google Vision 분석을 사용하려면 로그인이 필요합니다."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .noData:
            return "응답 데이터가 없습니다."
        case .parsingFailed:
            return "응답 파싱에 실패했습니다."
        case .apiError(let statusCode):
            return "이미지 분석 요청에 실패했습니다. (\(statusCode))"
        }
    }
}
