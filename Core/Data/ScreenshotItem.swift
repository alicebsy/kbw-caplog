import Foundation

struct ScreenshotItem: Codable, Hashable, Identifiable {
    let id: String
    let thumbnailUrl: URL
    let title: String?
    let createdAt: Date
}
