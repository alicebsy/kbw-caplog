import Foundation

// MARK: - 안정 버전 GPT 분류 함수
func classifyTextWithGPT_stable(
    prompt: String,
    apiKey: String,
    completion: @escaping (String, String) -> Void
) {
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        completion("❌ 잘못된 URL", "")
        return
    }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "model": "gpt-4o-mini",
        "messages": [
            ["role": "system", "content": "너는 분류 기준에 따라 스크린샷 텍스트를 정확히 분류하는 전문가야."],
            ["role": "user",   "content": prompt]
        ],
        "temperature": 0.2
    ]

    req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

    URLSession.shared.dataTask(with: req) { data, resp, err in
        // 1️⃣ 네트워크 오류 처리
        if let err = err {
            print("🌐 Network error:", err.localizedDescription)
            completion("❌ 네트워크 오류: \(err.localizedDescription)", "")
            return
        }

        guard let http = resp as? HTTPURLResponse else {
            completion("❌ 응답 없음", "")
            return
        }

        let status = http.statusCode
        var rawText = ""

        // 2️⃣ 응답 로그 찍기 (디버그용)
        if let data = data {
            rawText = String(data: data, encoding: .utf8) ?? ""
            print("📦 HTTP \(status) body:\n\(rawText)")
        }

        // 3️⃣ 수동 JSON 파싱 (Decodable 없이)
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion("❌ 파싱 실패", "")
            return
        }

        // 에러 응답 처리
        if status >= 400 {
            let errorMsg = (json["error"] as? [String: Any])?["message"] as? String ?? "상태코드 \(status)"
            completion("❌ API 에러: \(errorMsg)", "")
            return
        }
        
        if let error = json["error"] as? [String: Any],
           let errorMsg = error["message"] as? String {
            completion("❌ API 에러: \(errorMsg)", "")
            return
        }

        // 정상 응답 처리
        var content = ""
        var tokens = ""
        
        // content 추출
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let messageContent = message["content"] as? String {
            content = messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // tokens 추출
        if let usage = json["usage"] as? [String: Any],
           let totalTokens = usage["total_tokens"] as? Int {
            tokens = "\(totalTokens) tokens"
        }

        if content.isEmpty {
            completion("❌ 빈 응답", tokens)
        } else {
            completion(content, tokens)
        }
    }.resume()
}
