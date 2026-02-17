import Foundation
import UIKit

/// 스크린샷 업로드 (POST /api/screenshots/upload)
/// - APIConfig.baseURL 사용 (시뮬레이터: localhost, 실기기: 맥북 IP)
class ScreenshotUploader {

    static func upload(image: UIImage, userId: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let uploadURL = APIConfig.baseURL
            .appendingPathComponent(APIConfig.apiPrefix.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            .appendingPathComponent("screenshots")
            .appendingPathComponent("upload")

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // userId 필드
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)

        // file 필드
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // 종료 boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        // 업로드 요청
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "No Response", code: 0)))
                return
            }

            print("📡 상태코드:", httpResponse.statusCode)

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(NSError(domain: "Invalid JSON", code: 0)))
                return
            }

            completion(.success(json))
        }.resume()
    }
}
