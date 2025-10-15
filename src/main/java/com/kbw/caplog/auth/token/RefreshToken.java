package com.kbw.caplog.auth.token;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
@Entity
@Table(name = "refresh_tokens", indexes = {
        @Index(name = "idx_refresh_token_token", columnList = "token", unique = true),
        @Index(name = "idx_refresh_token_user_no", columnList = "userNo")
})
public class RefreshToken {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 512, unique = true)
    private String token;          // 실제 Refresh JWT 문자열

    @Column(nullable = false)
    private Long userNo;           // 소유자(User.userNo)

    @Column(nullable = false)
    private Instant expiresAt;     // 만료 시각(서버 검증용)

    @Column(nullable = false)
    private boolean revoked = false; // 로그아웃/회전 등에 의해 폐기되었는가

    @Column(nullable = false)
    private Instant createdAt;
}