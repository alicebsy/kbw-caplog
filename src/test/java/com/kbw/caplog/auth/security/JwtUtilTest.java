package com.kbw.caplog.auth.security;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class JwtUtilTest {

    private static final String STRONG_SECRET =
            "caplog-test-secret-that-is-longer-than-thirty-two-bytes";

    @Test
    void rejectsMissingOrWeakSecrets() {
        assertThrows(IllegalStateException.class, () -> new JwtUtil("", 1, 14));
        assertThrows(IllegalStateException.class, () -> new JwtUtil("too-short", 1, 14));
        assertThrows(IllegalStateException.class, () ->
                new JwtUtil("change-this-to-a-long-random-secret-please-please", 1, 14));
    }

    @Test
    void rejectsInvalidExpirationValues() {
        assertThrows(IllegalStateException.class, () -> new JwtUtil(STRONG_SECRET, 0, 14));
        assertThrows(IllegalStateException.class, () -> new JwtUtil(STRONG_SECRET, 1, 0));
    }

    @Test
    void createsAndValidatesAccessToken() {
        JwtUtil jwtUtil = new JwtUtil(STRONG_SECRET, 1, 14);
        String token = jwtUtil.generateAccessToken("user@example.com");

        assertEquals("user@example.com", jwtUtil.validateAndGetSubject(token));
    }

    @Test
    void rejectsBlankSubject() {
        JwtUtil jwtUtil = new JwtUtil(STRONG_SECRET, 1, 14);

        assertThrows(IllegalArgumentException.class, () -> jwtUtil.generateAccessToken(" "));
    }
}
