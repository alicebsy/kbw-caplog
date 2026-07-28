import Foundation

/// 외부 AI에 OCR 텍스트를 보내기 전에 대표적인 개인 식별 정보를 가립니다.
enum OCRPrivacyRedactor {
    private struct Rule {
        let pattern: String
        let replacement: String
    }

    private static let rules = [
        Rule(
            pattern: #"(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#,
            replacement: "[이메일 가림]"
        ),
        Rule(
            pattern: #"(?<!\d)(?:01[016789]|02|0[3-6][1-5])[-.\s]?\d{3,4}[-.\s]?\d{4}(?!\d)"#,
            replacement: "[전화번호 가림]"
        ),
        Rule(
            pattern: #"(?<!\d)\d{6}[-\s]?[1-8]\d{6}(?!\d)"#,
            replacement: "[주민번호 가림]"
        ),
        Rule(
            pattern: #"(?<!\d)(?:\d[ -]?){13,19}(?!\d)"#,
            replacement: "[카드번호 가림]"
        )
    ]

    static func redact(_ text: String) -> String {
        rules.reduce(text) { result, rule in
            result.replacingOccurrences(
                of: rule.pattern,
                with: rule.replacement,
                options: .regularExpression
            )
        }
    }
}
