//
//  FolderItem.swift
//  Caplog
//
//  Created by user on 10/16/25.
//


import Foundation

extension FolderItem {
    /// 기존 description 호출 호환용
    var description: String { summary }

    /// 기존 location 호출 호환용
    var location: String {
        fields["주소"] ?? fields["위치"] ?? fields["장소명"] ?? fields["가게명"] ?? ""
    }

    /// 혹시 예전 코드에서 imageName이 비어있으면 기본 이미지 대체
    var resolvedImageName: String {
        imageName ?? "placeholder"
    }
}
