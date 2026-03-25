//
//  UIImage+AverageColor.swift
//  쿠폰 카드 등 — 스크린샷 톤에 맞는 액센트 색 추출
//

import UIKit
import CoreImage

extension UIImage {
    /// 이미지 전체의 평균 색 (스크린샷 기반 카드 톤용)
    func caplogAverageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extent = inputImage.extent
        let extentVector = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: extentVector
        ]), let outputImage = filter.outputImage else { return nil }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        let r = CGFloat(bitmap[0]) / 255
        let g = CGFloat(bitmap[1]) / 255
        let b = CGFloat(bitmap[2]) / 255
        let a = CGFloat(bitmap[3]) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a > 0 ? a : 1)
    }
}
