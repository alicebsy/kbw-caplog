package com.kbw.caplog.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * /api/auth/logout 요청 바디
 * 단일 기기 로그아웃 : refreshToken 만 삭제
 * 모든 기기 로그아웃 : 해당 유저의 모든 refresh 삭제
 * */

@Getter
@NoArgsConstructor
public class LogoutRequest {
    @NotBlank
    private String refreshToken;  // 현재 기기에서 발급받은 리프레시 토큰
    private boolean allDevices;   // true 면 모든 기기 로그아웃
}