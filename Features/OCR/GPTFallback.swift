import Foundation

private struct AIClassifyRequest: Encodable {
    let prompt: String
}

private struct AIClassifyResponse: Decodable {
    let content: String
    let totalTokens: Int
}

/// OpenAI 키는 앱에 저장하지 않고, JWT로 인증된 CapLog 백엔드를 통해 분류한다.
func classifyTextWithGPT_stable(
    prompt: String,
    completion: @escaping (String, String) -> Void
) {
    Task {
        do {
            let response: AIClassifyResponse = try await APIClient().request(
                "POST",
                path: "/ai/classify",
                body: AIClassifyRequest(prompt: prompt),
                timeoutInterval: 90
            )
            await MainActor.run {
                completion(response.content, "\(response.totalTokens) tokens")
            }
        } catch {
            await MainActor.run {
                completion("❌ GPT 분류 요청 실패: \(error.localizedDescription)", "")
            }
        }
    }
}
