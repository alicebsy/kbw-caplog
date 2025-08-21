package com.kbw.caplog.common.exception;

import com.kbw.caplog.common.dto.ApiResponse;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * GlobalExceptionHandler
    : 프로젝트 전역에서 발생하는 예외를 한 곳에서 처리.
 *
 * - 장점:
 *   1) 모든 에러 응답이 같은 형식을 가지게 됨 (ApiResponse)
 *   2) 에러 발생 시 HTML 에러 페이지 대신 JSON 응답 반환
 *   3) 프론트엔드에서 예외 상황을 쉽게 처리 가능
 *
 * 사용 예시: 예외 발생 시
 *
 * throw new IllegalArgumentException("이메일 형식이 올바르지 않습니다.");
 *
 * 프론트엔드에서 받는 응답(JSON):
 * {
 *   "success": false,
 *   "message": "잘못된 요청: 이메일 형식이 올바르지 않습니다.",
 *   "data": null
 * }
 * -----------------------------------------------------
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    // 모든 예외 처리 (최상위)
    @ExceptionHandler(Exception.class)
    public ApiResponse<String> handleException(Exception e) {
        return ApiResponse.fail("서버 오류: " + e.getMessage());
    }

    // 잘못된 요청 처리
    @ExceptionHandler(IllegalArgumentException.class)
    public ApiResponse<String> handleIllegalArgument(IllegalArgumentException e) {
        return ApiResponse.fail("잘못된 요청: " + e.getMessage());
    }

    // 필요하면 추가 가능 (예: NullPointerException, CustomException 등)
}