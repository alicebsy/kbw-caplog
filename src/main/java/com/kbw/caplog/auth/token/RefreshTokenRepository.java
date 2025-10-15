// src/main/java/com/kbw/caplog/auth/token/RefreshTokenRepository.java
package com.kbw.caplog.auth.token;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/*
* RefreshToken CRUD
* */

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByToken(String token);
    void deleteByToken(String token);
    void deleteAllByUserNo(Long userNo);
}