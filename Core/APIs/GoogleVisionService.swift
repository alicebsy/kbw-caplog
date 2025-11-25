import Foundation
import UIKit

/// Google Vision API를 사용한 이미지 분석 서비스
class GoogleVisionService {
    
    // MARK: - API Configuration
    private var apiKey: String {
        guard let key = Bundle.main.infoDictionary?["GOOGLE_VISION_API_KEY"] as? String,
              !key.isEmpty else {
            print("⚠️ GOOGLE_VISION_API_KEY가 Info.plist에 없습니다.")
            return ""
        }
        print("✅ Google Vision API Key 로드됨: \(key.prefix(20))...")
        return key
    }
    
    // ✅ API 키를 쿼리 파라미터로 전달
    private var endpoint: String {
        return "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)"
    }
    
    // MARK: - OCR Methods (TEXT_DETECTION only)
    
    /// 이미지에서 텍스트 추출 (Google Vision API - TEXT_DETECTION)
    /// - Parameters:
    ///   - image: 분석할 UIImage
    ///   - completion: (추출된 텍스트, 에러) 콜백
    func extractText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // 1. 이미지를 Base64로 인코딩
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(VisionError.imageConversionFailed))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // 2. API 요청 Body 생성 (TEXT_DETECTION만)
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": [
                        "content": base64Image
                    ],
                    "features": [
                        [
                            "type": "TEXT_DETECTION",
                            "maxResults": 1
                        ]
                    ],
                    "imageContext": [
                        "languageHints": ["ko", "en"]
                    ]
                ]
            ]
        ]
        
        performVisionRequest(requestBody: requestBody, completion: completion)
    }
    
    /// 이미지에서 텍스트 추출 (async/await 버전)
    func extractText(from image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            extractText(from: image) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Label Detection Methods (객체/개념 탐지)
    
    /// 이미지에서 객체/개념 탐지 (Google Vision API - LABEL_DETECTION)
    /// - Parameters:
    ///   - image: 분석할 UIImage
    ///   - completion: ([레이블], 에러) 콜백
    func detectLabels(from image: UIImage, completion: @escaping (Result<[VisionLabel], Error>) -> Void) {
        // 1. 이미지를 Base64로 인코딩
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(VisionError.imageConversionFailed))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // 2. API 요청 Body 생성 (LABEL_DETECTION)
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": [
                        "content": base64Image
                    ],
                    "features": [
                        [
                            "type": "LABEL_DETECTION",
                            "maxResults": 10  // 최대 10개 레이블
                        ]
                    ]
                ]
            ]
        ]
        
        // 3. URL 생성
        guard let url = URL(string: endpoint) else {
            completion(.failure(VisionError.invalidURL))
            return
        }
        
        // 4. URLRequest 설정
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        print("🌐 Google Vision LABEL_DETECTION 요청: \(endpoint.prefix(80))...")
        
        // 5. API 호출
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 에러: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(VisionError.noData))
                return
            }
            
            // 🔍 응답 디버깅
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Google Vision LABEL 응답:\n\(responseString.prefix(500))")
            }
            
            // 6. 응답 파싱
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let responses = json["responses"] as? [[String: Any]],
                   let firstResponse = responses.first {
                    
                    // 에러 체크
                    if let error = firstResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        print("❌ Google Vision API Error: \(message)")
                        completion(.failure(VisionError.apiError(message)))
                        return
                    }
                    
                    // 레이블 추출
                    if let labelAnnotations = firstResponse["labelAnnotations"] as? [[String: Any]] {
                        let labels = labelAnnotations.compactMap { annotation -> VisionLabel? in
                            guard let description = annotation["description"] as? String else { return nil }
                            let confidence = annotation["score"] as? Double ?? 0.0
                            return VisionLabel(description: description, confidence: confidence)
                        }
                        print("✅ Google Vision LABEL_DETECTION 성공: \(labels.count)개 탐지")
                        completion(.success(labels))
                    } else {
                        // 레이블이 없는 경우
                        print("⚠️ 이미지에서 레이블을 찾을 수 없습니다.")
                        completion(.success([]))
                    }
                } else {
                    print("❌ 파싱 실패: 예상하지 못한 응답 형식")
                    completion(.failure(VisionError.parsingFailed))
                }
            } catch {
                print("❌ JSON 파싱 에러: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// 이미지에서 객체/개념 탐지 (async/await 버전)
    func detectLabels(from image: UIImage) async throws -> [VisionLabel] {
        try await withCheckedThrowingContinuation { continuation in
            detectLabels(from: image) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Private Helper
    
    /// 공통 Vision API 요청 처리 (텍스트 추출용)
    private func performVisionRequest(
        requestBody: [String: Any],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // 3. URL 생성
        guard let url = URL(string: endpoint) else {
            completion(.failure(VisionError.invalidURL))
            return
        }
        
        // 4. URLRequest 설정
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        print("🌐 Google Vision API 요청: \(endpoint.prefix(80))...")
        
        // 5. API 호출
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 에러: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(VisionError.noData))
                return
            }
            
            // 🔍 응답 디버깅
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Google Vision API 응답:\n\(responseString.prefix(500))")
            }
            
            // 6. 응답 파싱
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let responses = json["responses"] as? [[String: Any]],
                   let firstResponse = responses.first {
                    
                    // 에러 체크
                    if let error = firstResponse["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        print("❌ Google Vision API Error: \(message)")
                        completion(.failure(VisionError.apiError(message)))
                        return
                    }
                    
                    // 텍스트 추출
                    if let textAnnotations = firstResponse["textAnnotations"] as? [[String: Any]],
                       let firstAnnotation = textAnnotations.first,
                       let description = firstAnnotation["description"] as? String {
                        print("✅ Google Vision OCR 성공: \(description.prefix(100))...")
                        completion(.success(description))
                    } else {
                        // 텍스트가 없는 경우
                        print("⚠️ 이미지에서 텍스트를 찾을 수 없습니다.")
                        completion(.success(""))
                    }
                } else {
                    print("❌ 파싱 실패: 예상하지 못한 응답 형식")
                    completion(.failure(VisionError.parsingFailed))
                }
            } catch {
                print("❌ JSON 파싱 에러: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Data Models
struct VisionLabel: Codable {
    let description: String
    let confidence: Double
    
    var confidencePercentage: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

// MARK: - Error Types
enum VisionError: LocalizedError {
    case imageConversionFailed
    case invalidURL
    case noData
    case parsingFailed
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "이미지 변환에 실패했습니다."
        case .invalidURL:
            return "잘못된 URL입니다."
        case .noData:
            return "응답 데이터가 없습니다."
        case .parsingFailed:
            return "응답 파싱에 실패했습니다."
        case .apiError(let message):
            return "API 에러: \(message)"
        }
    }
}
