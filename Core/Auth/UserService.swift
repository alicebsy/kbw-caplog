//
//  UserService.swift
//  caplog
//
//  Created by user on 10/13/25.
//


import Foundation

struct UserService {
    private let client = APIClient()

    func fetchMe() async throws -> UserProfile {
        try await client.request("GET", path: Endpoints.me)
    }

    func updateMe(nickname: String, gender: MyPageViewModel.Gender?, birthday: Date?) async throws -> UserProfile {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let body = UpdateUserProfileRequest(
            nickname: nickname,
            gender: gender.map { $0 == .male ? "M" : "F" },
            birthday: birthday.map { df.string(from: $0) }
        )
        return try await client.request("PUT", path: Endpoints.updateMe, body: body)
    }

    func logout() async throws {
        try await client.requestVoid("POST", path: Endpoints.logout)
    }
}
