// src/main/java/com/kbw/caplog/auth/dto/RefreshRequest.java
package com.kbw.caplog.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;


// /api/auth/refresh 요청 바디
// 클라이언트가 저장하고 있던 refreshToken 제출

@Getter
@NoArgsConstructor
public class RefreshRequest {
    @NotBlank
    private String refreshToken;
}