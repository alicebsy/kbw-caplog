//
//  CardImageStore.swift
//  Caplog
//
//  카드에 맞는 스크린샷 이미지를 앱 전용 로컬 저장소에 저장/로드
//

import UIKit

enum CardImageStore {
    private static let directoryName = "CardImages"
    
    private static var directoryURL: URL {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return baseURL.appendingPathComponent(directoryName, isDirectory: true)
    }

    private static var legacyDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName, isDirectory: true)
    }
    
    /// thumbnailURL/screenshotURLs가 UUID 형식인지 (스크린샷에서 생성된 카드)
    static func isLocalScreenshot(id: String?) -> Bool {
        guard let id = id, !id.isEmpty else { return false }
        // UUID 형식: 8-4-4-4-12 (총 36자, 하이픈 포함)
        let pattern = "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"
        return id.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 이미지를 로컬에 저장 (스크린샷→카드 생성 시 호출)
    @discardableResult
    static func save(image: UIImage, id: String) -> Bool {
        guard prepareDirectory(),
              let data = image.jpegData(compressionQuality: 0.8) else {
            return false
        }
        let fileURL = directoryURL.appendingPathComponent("\(id).jpg")
        do {
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            try protect(fileURL)
            try excludeFromBackup(fileURL)
            return true
        } catch {
            print("❌ 카드 이미지 로컬 저장 실패: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 저장된 이미지 파일 경로
    static func fileURL(for id: String) -> URL? {
        let url = directoryURL.appendingPathComponent("\(id).jpg")
        if FileManager.default.fileExists(atPath: url.path) {
            try? protect(url)
            try? excludeFromBackup(url)
            return url
        }

        // 이전 버전의 Documents 저장 이미지는 최초 접근 시 보호된 앱 저장소로 이동합니다.
        let legacyURL = legacyDirectoryURL.appendingPathComponent("\(id).jpg")
        guard FileManager.default.fileExists(atPath: legacyURL.path),
              prepareDirectory() else {
            return nil
        }
        do {
            try FileManager.default.moveItem(at: legacyURL, to: url)
            try protect(url)
            try excludeFromBackup(url)
            return url
        } catch {
            print("❌ 이전 카드 이미지 마이그레이션 실패: \(error.localizedDescription)")
            return legacyURL
        }
    }
    
    /// 저장된 이미지 로드
    static func load(id: String) -> UIImage? {
        guard let url = fileURL(for: id),
              let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else { return nil }
        return img
    }

    /// 서버가 발급한 카드 ID로 로컬 이미지 키를 바꿔 재실행 후에도 연결을 유지합니다.
    @discardableResult
    static func move(from sourceId: String, to destinationId: String) -> Bool {
        guard sourceId != destinationId,
              let sourceURL = fileURL(for: sourceId),
              prepareDirectory() else {
            return sourceId == destinationId && fileURL(for: sourceId) != nil
        }
        let destinationURL = directoryURL.appendingPathComponent("\(destinationId).jpg")
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            try protect(destinationURL)
            try excludeFromBackup(destinationURL)
            return true
        } catch {
            print("❌ 카드 이미지 로컬 키 변경 실패: \(error.localizedDescription)")
            return false
        }
    }

    static func delete(id: String) {
        guard let url = fileURL(for: id) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("❌ 카드 이미지 로컬 삭제 실패: \(error.localizedDescription)")
        }
    }

    private static func prepareDirectory() -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
            try protect(directoryURL)
            try excludeFromBackup(directoryURL)
            return true
        } catch {
            print("❌ 카드 이미지 저장소 준비 실패: \(error.localizedDescription)")
            return false
        }
    }

    private static func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }

    private static func protect(_ url: URL) throws {
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }
}
