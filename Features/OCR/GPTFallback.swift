import Foundation

// MARK: - OpenAI 전용 URLSession (QUIC 연결 끊김 -1005 완화: 공유 풀 사용 안 함)
private let gptURLSession: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 60
    config.timeoutIntervalForResource = 120
    config.waitsForConnectivity = false
    return URLSession(configuration: config)
}()

// MARK: - 안정 버전 GPT 분류 함수 (재시도 + 타임아웃 60초)
func classifyTextWithGPT_stable(
    prompt: String,
    apiKey: String,
    completion: @escaping (String, String) -> Void
) {
    let maxAttempts = 4
    var attempt = 0

    func performRequest() {
        attempt += 1
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion("❌ 잘못된 URL", "")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "너는 분류 기준에 따라 스크린샷 텍스트를 정확히 분류하는 전문가야. 응답은 반드시 지정된 JSON 스키마만 출력해."],
                ["role": "user",   "content": prompt]
            ],
            "temperature": 0.2,
            "response_format": ["type": "json_object"]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        // QUIC(HTTP/3) 연결이 곧바로 끊기는 -1005 완화: 전용 ephemeral 세션 + 재시도 간격 4초
        gptURLSession.dataTask(with: req) { data, resp, err in
            if let err = err as NSError? {
                let code = err.code
                let domain = err.domain
                let msg = err.localizedDescription
                print("[Caplog GPT] 네트워크 에러 상세: domain=\(domain), code=\(code), \(msg)")
                // -1005(connection lost, QUIC path unavailable 등), -1001 타임아웃, -1009 오프라인, -1004 연결 실패, -1200 SSL
                let isRetryable = (code == NSURLErrorNetworkConnectionLost || code == NSURLErrorTimedOut
                    || code == NSURLErrorNotConnectedToInternet || code == NSURLErrorSecureConnectionFailed
                    || code == NSURLErrorCannotConnectToHost)
                let retryDelay: TimeInterval = (code == NSURLErrorNetworkConnectionLost) ? 4.0 : 2.0
                if isRetryable && attempt < maxAttempts {
                    print("🌐 네트워크 오류(재시도 \(attempt)/\(maxAttempts), \(retryDelay)초 후): \(msg)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { performRequest() }
                    return
                }
                completion("❌ 네트워크 오류: \(msg)", "")
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
        
        // content 추출 (API가 문자열 또는 배열로 줄 수 있음)
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any] {
            let raw = message["content"]
            if let str = raw as? String {
                content = str.trimmingCharacters(in: .whitespacesAndNewlines)
                print("[Caplog GPT] content 타입: 문자열, 길이 \(content.count)")
            } else if let parts = raw as? [[String: Any]] {
                content = parts.compactMap { part -> String? in
                    guard (part["type"] as? String) == "text" else { return nil }
                    return (part["text"] as? String) ?? (part["content"] as? String)
                }.joined().trimmingCharacters(in: .whitespacesAndNewlines)
                print("[Caplog GPT] content 타입: 배열(\(parts.count)개), 합쳐진 길이 \(content.count)")
            } else if raw != nil && !(raw is NSNull) {
                // NSNull/기타 타입이면 문자열로 변환 시도 (방어)
                let fallback = "\(raw)".trimmingCharacters(in: .whitespacesAndNewlines)
                if !fallback.isEmpty {
                    content = fallback
                    print("[Caplog GPT] content 타입: fallback 문자열, 길이 \(content.count)")
                } else {
                    print("[Caplog GPT] content 추출 실패: message.content 타입이 문자열/배열 아님. raw=\(String(describing: raw))")
                }
            } else {
                print("[Caplog GPT] content 추출 실패: message.content null/없음. raw=\(String(describing: raw))")
            }
        } else {
            print("[Caplog GPT] choices/message 없음. choices 존재=\(json["choices"] != nil)")
        }
        
        // tokens 추출
        if let usage = json["usage"] as? [String: Any],
           let totalTokens = usage["total_tokens"] as? Int {
            tokens = "\(totalTokens) tokens"
        }

        if content.isEmpty {
            print("[Caplog GPT] ❌ 빈 응답 → completion(\"❌ 빈 응답\") 호출")
            completion("❌ 빈 응답", tokens)
        } else {
            completion(content, tokens)
        }
        }.resume()
    }
    performRequest()
}
