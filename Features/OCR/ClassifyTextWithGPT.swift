import Foundation

/// 기존 호출부 호환용 래퍼. 실제 요청은 인증된 CapLog 백엔드가 수행한다.
func classifyTextWithGPT(
    prompt: String,
    completion: @escaping (String, String) -> Void
) {
    classifyTextWithGPT_stable(prompt: prompt, completion: completion)
}
