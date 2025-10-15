package com.kbw.caplog.user;

import jakarta.persistence.*;
import lombok.*;

@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "users", uniqueConstraints = {
        @UniqueConstraint(name = "uk_users_email", columnNames = "email"),
        @UniqueConstraint(name = "uk_users_user_id", columnNames = "userId")
})
public class User {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long userNo;               // PK

    @Column(nullable = false, length = 120)
    private String email;              // 로그인용 이메일 (unique)

    @Column(nullable = false, length = 255)
    private String password;           // BCrypt 해시 저장

    @Column(nullable = false, length = 40)
    private String userId;             // 공개용 아이디/닉네임 (unique)

    @Column(nullable = false, length = 50)
    private String name;               // 실명(초기 가입 시 수집)

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role = Role.ROLE_USER;                 // ROLE_USER, ROLE_ADMIN 등

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Provider provider = Provider.LOCAL;         // LOCAL, GOOGLE, KAKAO, APPLE (확장 대비)

    public enum Role { ROLE_USER, ROLE_ADMIN }
    public enum Provider { LOCAL, GOOGLE, KAKAO, APPLE }
}