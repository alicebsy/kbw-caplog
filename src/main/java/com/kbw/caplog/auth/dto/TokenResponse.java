package com.kbw.caplog.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor

// 로그인/리프레시 응답 : 항상 Access + Refresh 반환

public class TokenResponse {
    private String accessToken;
    private String refreshToken; // refresh API에서는 그대로 재사용(혹은 회전 시 교체)
}