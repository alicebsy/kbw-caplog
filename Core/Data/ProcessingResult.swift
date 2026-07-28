import Foundation
import UIKit

/// 스크린샷 처리 결과 (Card + 원본 데이터)
struct ProcessingResult {
    let card: Card
    let ocrText: [String]  // VisionKit OCR 원본 텍스트 (라인 단위)
    let imageLabels: [ImageLabel]  // Apple Vision 온디바이스 이미지 분류 결과
    let preprocessedImage: UIImage?  // 전처리된 이미지
    let apiUsage: String  // 토큰 사용량
}
