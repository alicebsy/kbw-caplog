//
//  Item.swift
//  Caplog
//
//  (SwiftData @Model 제거 — 프로젝트에서 미사용, 매크로 오류 원인 제거)
//

import Foundation

/// 더 이상 SwiftData 미사용. 필요 시 Card/다른 모델 사용.
struct Item: Identifiable {
    let id: UUID
    var timestamp: Date

    init(id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.timestamp = timestamp
    }
}
