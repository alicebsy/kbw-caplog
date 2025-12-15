import Foundation

// ✅ 충돌 방지를 위해 GPTAPIError 로 이름 변경
private struct ChatAPIResponse: Decodable {
    struct Choice: Decodable { let message: Msg? }
    struct Msg: Decodable { let content: String? }
    let choices: [Choice]?
    let usage: GPTAPIUsage?
    let error: GPTAPIError?
}

private struct GPTAPIUsage: Decodable {
    let total_tokens: Int?
}

// ✅ 이름 변경
private struct GPTAPIError: Decodable {
    let message: String?
    let type: String?
    let code: String?
}

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

        // 3️⃣ JSON 디코딩
        if let data = data,
           let parsed = try? JSONDecoder().decode(ChatAPIResponse.self, from: data) {

            // 에러 응답 처리
            if status >= 400 || parsed.error != nil {
                let msg = parsed.error?.message ?? "상태코드 \(status)"
                completion("❌ API 에러: \(msg)", "")
                return
            }

            // 정상 응답 처리
            let content = parsed.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let tokens = parsed.usage?.total_tokens.map { "\($0) tokens" } ?? ""

            if content.isEmpty {
                completion("❌ 빈 응답", tokens)
            } else {
                completion(content, tokens)
            }
        } else {
            completion("❌ 파싱 실패", "")
        }
    }.resume()
}
