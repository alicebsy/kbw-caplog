import Foundation

/// 기본 로그인/회원가입/소셜 교환 응답
// 백엔에 맞게 수정함
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

//
// 아래는 선택적으로 함께 써도 좋은 보조 모델들입니다.
// 백엔드 스펙이 확정되면 필요 없는 건 지워도 됩니다.
//

/// (선택) 토큰 재발급 응답 예시
/// 서버 스펙에 맞춰 키 이름을 수정하세요.
struct RefreshTokenResponse: Decodable {
    let jwt: String
    // 필요 시 refreshToken 등도 추가
    // let refreshToken: String
}

/// (선택) 공통 에러 응답 파싱용
/// {"message":"..."} 형태일 때 사용
struct APIErrorResponse: Decodable, Error {
    let message: String
}

/// (선택) 204 No Content 등 바디 없는 성공 응답 표현용
struct EmptyResponse: Decodable {}
