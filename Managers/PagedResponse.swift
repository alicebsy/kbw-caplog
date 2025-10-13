import Foundation

struct PagedResponse<T: Codable>: Codable {
    let items: [T]
    let nextCursor: String?
}
