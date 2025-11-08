import Foundation

/// GPT를 이용해 OCR 텍스트를 분류하는 함수 (Info.plist 기반 자동 키 로드 + 안정화 버전)
func classifyTextWithGPT(
    prompt: String,
    apiKey: String = "",
    completion: @escaping (String, String) -> Void
) {
    // ✅ 1️⃣ Info.plist에서 GPT_API_KEY 자동 로드
    var finalKey = apiKey
    if finalKey.isEmpty {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["GPT_API_KEY"] as? String,
           !key.isEmpty {
            finalKey = key
            print("✅ Info.plist에서 GPT_API_KEY 불러오기 성공: \(key.prefix(10))...")
        } else {
            print("❌ Info.plist에서 GPT_API_KEY를 불러올 수 없습니다.")
            completion("❌ Info.plist에 API 키가 없습니다.", "")
            return
        }
    }
    
    // ✅ 2️⃣ URLSession 구성 (네트워크 안정성 향상)
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = true
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    config.allowsConstrainedNetworkAccess = true
    config.allowsExpensiveNetworkAccess = true
    let session = URLSession(configuration: config)
    
    // ✅ 3️⃣ OpenAI Chat Completions 엔드포인트
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        completion("❌ 잘못된 URL", "")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(finalKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // ✅ 4️⃣ 요청 Body (기존 그대로 유지)
    let body: [String: Any] = [
        "model": "gpt-4o-mini",
        "messages": [
            ["role": "system", "content": "너는 분류 기준에 따라 스크린샷 텍스트를 정확히 분류하는 전문가야."],
            ["role": "user", "content": prompt]
        ],
        "temperature": 0.2
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    // ✅ 5️⃣ 요청 전송 (세션 기반)
    let task = session.dataTask(with: request) { data, response, error in
        
        // 🧩 네트워크 에러 처리
        if let error = error {
            print("🌐 네트워크 에러: \(error.localizedDescription)")
            completion("❌ 네트워크 오류: \(error.localizedDescription)", "")
            return
        }
        
        // 🧩 응답 코드 확인
        if let http = response as? HTTPURLResponse {
            print("📡 HTTP 상태 코드: \(http.statusCode)")
        } else {
            print("⚠️ HTTP 응답을 읽을 수 없습니다.")
        }
        
        // 🧩 데이터 유효성 검사
        guard let data = data else {
            completion("❌ 응답 데이터 없음", "")
            return
        }
        
        // 🧩 원본 로그 출력
        if let raw = String(data: data, encoding: .utf8) {
            print("📦 GPT 응답 원문:\n\(raw)")
        }
        
        // 🧩 JSON 파싱
        guard let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion("❌ GPT 응답 파싱 실패", "")
            return
        }
        
        // 🧩 GPT 메시지 본문 추출
        let choice = (result["choices"] as? [[String: Any]])?.first
        let message = choice?["message"] as? [String: Any]
        let content = message?["content"] as? String ?? "❌ GPT 결과 없음"
        
        // 🧩 토큰 사용량 추출
        let usageDict = result["usage"] as? [String: Any]
        let totalTokens = usageDict?["total_tokens"] as? Int ?? 0
        
        // 🧩 최종 콜백 실행
        completion(content.trimmingCharacters(in: .whitespacesAndNewlines), "\(totalTokens) tokens")
    }
    
    // ✅ 요청 시작
    task.resume()
}
