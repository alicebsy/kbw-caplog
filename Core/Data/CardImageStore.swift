//
//  CardImageStore.swift
//  Caplog
//
//  카드에 맞는 스크린샷 이미지를 로컬에 저장/로드
//

import UIKit

enum CardImageStore {
    private static let directoryName = "CardImages"
    
    private static var directoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName)
    }
    
    /// thumbnailURL/screenshotURLs가 UUID 형식인지 (스크린샷에서 생성된 카드)
    static func isLocalScreenshot(id: String?) -> Bool {
        guard let id = id, !id.isEmpty else { return false }
        // UUID 형식: 8-4-4-4-12 (총 36자, 하이픈 포함)
        let pattern = "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"
        return id.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 이미지를 로컬에 저장 (스크린샷→카드 생성 시 호출)
    static func save(image: UIImage, id: String) {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("\(id).jpg")
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: fileURL)
    }
    
    /// 저장된 이미지 파일 경로
    static func fileURL(for id: String) -> URL? {
        let url = directoryURL.appendingPathComponent("\(id).jpg")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    /// 저장된 이미지 로드
    static func load(id: String) -> UIImage? {
        guard let url = fileURL(for: id),
              let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else { return nil }
        return img
    }
}
