package com.kbw.caplog.auth.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;

@Component
public class JwtUtil {

    private static final int MIN_SECRET_BYTES = 32;
    private static final String INSECURE_DEFAULT = "change-this-to-a-long-random-secret-please-please";

    private final SecretKey secretKey;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;

    public JwtUtil(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-hours:1}") int accessHours,
            @Value("${jwt.refresh-days:14}") int refreshDays
    ) {
        if (secret == null || secret.isBlank() || INSECURE_DEFAULT.equals(secret)) {
            throw new IllegalStateException("JWT_SECRET must be set to a unique random value");
        }
        byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < MIN_SECRET_BYTES) {
            throw new IllegalStateException("JWT_SECRET must be at least 32 bytes");
        }
        if (accessHours <= 0 || refreshDays <= 0) {
            throw new IllegalStateException("JWT expiration values must be positive");
        }
        this.secretKey = Keys.hmacShaKeyFor(keyBytes);
        this.accessExpirationMs = accessHours * 3600L * 1000;
        this.refreshExpirationMs = refreshDays * 24L * 3600 * 1000;
    }

    public String generateAccessToken(String email) {
        requireSubject(email);
        return Jwts.builder()
                .setSubject(email)
                .setIssuedAt(new Date())
                .setExpiration(Date.from(Instant.now().plusMillis(accessExpirationMs)))
                .signWith(secretKey)
                .compact();
    }

    public String generateRefreshToken(String email) {
        requireSubject(email);
        return Jwts.builder()
                .setSubject(email)
                .setIssuedAt(new Date())
                .setExpiration(Date.from(Instant.now().plusMillis(refreshExpirationMs)))
                .signWith(secretKey)
                .compact();
    }

    public Instant getExpiration(String token) {
        Date exp = Jwts.parserBuilder()
                .setSigningKey(secretKey)
                .build()
                .parseClaimsJws(token)
                .getBody()
                .getExpiration();
        return exp != null ? exp.toInstant() : null;
    }

    public String validateAndGetSubject(String token) {
        Jws<Claims> jws = Jwts.parserBuilder()
                .setSigningKey(secretKey)
                .build()
                .parseClaimsJws(token);
        return jws.getBody().getSubject();
    }

    private static void requireSubject(String subject) {
        if (subject == null || subject.isBlank()) {
            throw new IllegalArgumentException("JWT subject must not be blank");
        }
    }
}
