
package com.kbw.caplog.auth.service;

import com.kbw.caplog.auth.dto.LoginRequest;
import com.kbw.caplog.auth.dto.RefreshRequest;
import com.kbw.caplog.auth.dto.SignupRequest;
import com.kbw.caplog.auth.dto.TokenResponse;
import com.kbw.caplog.auth.security.JwtUtil;
import com.kbw.caplog.auth.token.RefreshToken;
import com.kbw.caplog.auth.token.RefreshTokenRepository;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RefreshTokenRepository refreshTokenRepository;

    // 회원가입
    @Transactional
    public void signup(SignupRequest request) {
        // 중복 검사
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("이미 사용 중인 이메일입니다.");
        }
        if (userRepository.existsByUserId(request.getUserId())) {
            throw new RuntimeException("이미 사용 중인 아이디입니다.");
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .name(request.getName())
                .userId(request.getUserId())  // ✅ 수정됨: 요청에서 직접 받기
                .build();

        userRepository.save(user);
    }

    // 로그인: access + refresh 발급, refresh 저장
    @Transactional
    public TokenResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("비밀번호가 틀렸습니다.");
        }

        String access = jwtUtil.generateAccessToken(user.getEmail());
        String refresh = jwtUtil.generateRefreshToken(user.getEmail());

        // DB 저장(현 기기 세션)
        refreshTokenRepository.save(RefreshToken.builder()
                .token(refresh)
                .userNo(user.getUserNo())
                .expiresAt(jwtUtil.getExpiration(refresh))  // JwtUtil 에 이미 메서드 있음
                .revoked(false)
                .createdAt(Instant.now())
                .build());

        return new TokenResponse(access, refresh);
    }

    // refresh: 사용한 refresh 토큰을 폐기하고 access/refresh를 모두 회전한다.
    @Transactional
    public TokenResponse refresh(RefreshRequest request) {
        String refreshToken = request.getRefreshToken();
        // 1) 서명/만료 검증
        String email = jwtUtil.validateAndGetSubject(refreshToken);

        // 2) DB 에서 존재 & revoked 아님 확인
        RefreshToken stored = refreshTokenRepository.findByToken(refreshToken)
                .orElseThrow(() -> new RuntimeException("리프레시 토큰이 유효하지 않습니다."));
        if (stored.isRevoked()) {
            throw new RuntimeException("이미 폐기된 리프레시 토큰입니다.");
        }
        if (stored.getExpiresAt() != null && stored.getExpiresAt().isBefore(Instant.now())) {
            // 만료된 건 정리도 해주기
            refreshTokenRepository.deleteByToken(refreshToken);
            throw new RuntimeException("리프레시 토큰이 만료되었습니다. 다시 로그인 해주세요.");
        }

        // 3) 재사용 공격을 줄이기 위해 refresh 토큰도 함께 회전
        String newAccess = jwtUtil.generateAccessToken(email);
        String newRefresh = jwtUtil.generateRefreshToken(email);
        stored.setRevoked(true);
        refreshTokenRepository.save(stored);
        refreshTokenRepository.save(RefreshToken.builder()
                .token(newRefresh)
                .userNo(stored.getUserNo())
                .expiresAt(jwtUtil.getExpiration(newRefresh))
                .revoked(false)
                .createdAt(Instant.now())
                .build());
        return new TokenResponse(newAccess, newRefresh);
    }

    // 로그아웃: 단일 기기 or 전체 기기
    @Transactional
    public void logout(String refreshToken, boolean allDevices) {
        // 토큰 검증 후 누구 것인지 확인
        String email = jwtUtil.validateAndGetSubject(refreshToken);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        if (allDevices) {
            // 해당 유저의 모든 리프레시 삭제
            refreshTokenRepository.deleteAllByUserNo(user.getUserNo());
        } else {
            // 현재 기기의 리프레시만 삭제(없으면 조용히 통과)
            refreshTokenRepository.deleteByToken(refreshToken);
        }
    }

    /** 비밀번호 변경 (JWT Bearer 인증된 사용자) */
    @Transactional
    public void changePassword(String email, String currentPassword, String newPassword) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
            throw new RuntimeException("현재 비밀번호가 일치하지 않습니다.");
        }
        if (passwordEncoder.matches(newPassword, user.getPassword())) {
            throw new IllegalArgumentException("새 비밀번호는 현재 비밀번호와 달라야 합니다.");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }
}
