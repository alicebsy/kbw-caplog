package com.kbw.caplog.auth.controller;

import com.kbw.caplog.auth.dto.LoginRequest;
import com.kbw.caplog.auth.dto.RefreshRequest;
import com.kbw.caplog.auth.dto.SignupRequest;
import com.kbw.caplog.auth.dto.TokenResponse;
import com.kbw.caplog.auth.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 인증 API 컨트롤러
 * - POST /api/auth/signup: 회원가입
 * - POST /api/auth/login: 로그인 (accessToken, refreshToken 반환)
 * - POST /api/auth/refresh: 토큰 갱신
 * - POST /api/auth/logout: 로그아웃 (선택적 refreshToken 전송)
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<Void> signup(@Valid @RequestBody SignupRequest request) {
        authService.signup(request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(authService.refresh(request));
    }

    /**
     * 비밀번호 변경 (JWT Bearer 필요)
     * - PUT /api/auth/password
     */
    @PutMapping("/password")
    public ResponseEntity<Void> changePassword(
            org.springframework.security.core.Authentication auth,
            @RequestBody Map<String, String> body
    ) {
        String currentPassword = body != null ? body.get("currentPassword") : null;
        String newPassword = body != null ? body.get("newPassword") : null;
        if (currentPassword == null || newPassword == null || newPassword.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        authService.changePassword(auth.getName(), currentPassword, newPassword);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestBody(required = false) Map<String, Object> body) {
        String refreshToken = body != null && body.get("refreshToken") != null
                ? body.get("refreshToken").toString()
                : null;
        boolean allDevices = body != null && Boolean.TRUE.equals(body.get("allDevices"));
        if (refreshToken != null && !refreshToken.isBlank()) {
            authService.logout(refreshToken, allDevices);
        }
        return ResponseEntity.ok().build();
    }
}
