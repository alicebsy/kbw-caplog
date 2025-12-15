package com.kbw.caplog.common.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * ApiResponse
 * : 모든 API 응답을 이 클래스로 감싸서 프론트엔드/앱이 일관된 형태로 응답을 받을 수 있게 함
 */

/* 사용 예시: Controller 안에서
 * @GetMapping("/health")
 * public ApiResponse<String> healthCheck() {
 *     return ApiResponse.success("OK", "서버 정상 작동");
 * }
 */

/* // 프론트엔드에서 받는 응답 예시(JSON):
 * {
 *   "success": true,
 *   "message": "서버 정상 작동",
 *   "data": "OK"
 * }
 */


@Getter
@AllArgsConstructor
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;

    // 성공 응답 (data + message 둘 다 있는 경우)
    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(true, message, data);
    }

    // 성공 응답 (data만 있는 경우)
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, null, data);
    }

   // 성공 응답 (message만 있는 경우)
    public static <T> ApiResponse<T> success(String message) {
        return new ApiResponse<>(true, message, null);
    }

    // 실패 응답
    public static <T> ApiResponse<T> fail(String message) {
        return new ApiResponse<>(false, message, null);
    }
}

