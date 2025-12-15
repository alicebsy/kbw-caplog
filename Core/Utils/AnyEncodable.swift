import Foundation

/// Encodable 제네릭 우회용 래퍼 (여러 API 공통 사용)
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ wrapped: T) {
        self._encode = wrapped.encode
    }
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
