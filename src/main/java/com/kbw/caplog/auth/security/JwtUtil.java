package com.kbw.caplog.auth.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

/**
 * JWT Access / Refresh Token 발급 및 검증 유틸
 */
@Component
public class JwtUtil {

    private final String secret; // 서명에 사용할 비밀키(환경변수/설정으로 주입)
    private final long accessHours;   // Access 토큰 만료 시간 (시간 단위)
    private final long refreshDays;   // Refresh 토큰 만료 시간 (일 단위)
    private Key key; // 실제 서명에 쓰이는 Key 객체

    // 생성자
    public JwtUtil(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-hours}") long accessHours,
            @Value("${jwt.refresh-days}") long refreshDays
    ) {
        this.secret = secret;
        this.accessHours = accessHours;
        this.refreshDays = refreshDays;
    }

    // 서버 시작 시 1회 실행
    @PostConstruct
    public void init() {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    // Access Token 발급
    public String generateAccessToken(String email) {
        Instant now = Instant.now();
        Instant exp = now.plus(accessHours, ChronoUnit.HOURS);

        return Jwts.builder()
                .setSubject(email)                      // 토큰 주체
                .setIssuedAt(Date.from(now))            // 발급 시각
                .setExpiration(Date.from(exp))          // 만료 시각
                .signWith(key, SignatureAlgorithm.HS256) // 비밀키로 서명
                .compact(); // JWT 문자열로 직렬화
    }

    // Refresh Token 발급
    public String generateRefreshToken(String email) {
        Instant now = Instant.now();
        Instant exp = now.plus(refreshDays, ChronoUnit.DAYS);

        return Jwts.builder()
                .setSubject(email)
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(exp))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    // 토큰에서 email(subject) 추출 및 검증
    public String validateAndGetSubject(String token) {
        try {
            return Jwts.parserBuilder()
                    .setSigningKey(key)             // 서명 검증용 키
                    .build()
                    .parseClaimsJws(token)          // 서명/만료 검증
                    .getBody()
                    .getSubject();
        } catch (ExpiredJwtException e) {
            throw new RuntimeException("토큰이 만료되었습니다.", e);
        } catch (JwtException e) {
            throw new RuntimeException("토큰이 유효하지 않습니다.", e);
        }
    }

    // 토큰 만료 시각 추출
    public Instant getExpiration(String token) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();
        return claims.getExpiration().toInstant();
    }
}