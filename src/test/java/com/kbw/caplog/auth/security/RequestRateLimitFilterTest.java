package com.kbw.caplog.auth.security;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RequestRateLimitFilterTest {

    private final Clock clock = Clock.fixed(
            Instant.parse("2026-07-27T00:00:00Z"),
            ZoneOffset.UTC
    );

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void limitsRepeatedLoginAttemptsByRemoteAddress() throws Exception {
        var filter = new RequestRateLimitFilter(false, clock);
        var allowedRequests = new AtomicInteger();
        FilterChain chain = (request, response) -> allowedRequests.incrementAndGet();

        for (int i = 0; i < 5; i++) {
            var response = execute(
                    filter, chain, "POST", "/api/auth/login", "203.0.113.10"
            );
            assertEquals(200, response.getStatus());
        }

        var rejected = execute(
                filter, chain, "POST", "/api/auth/login", "203.0.113.10"
        );

        assertEquals(5, allowedRequests.get());
        assertEquals(429, rejected.getStatus());
        assertNotNull(rejected.getHeader("Retry-After"));
        assertEquals("no-store", rejected.getHeader("Cache-Control"));
    }

    @Test
    void keepsLoginLimitsSeparateForDifferentAddresses() throws Exception {
        var filter = new RequestRateLimitFilter(false, clock);
        var allowedRequests = new AtomicInteger();
        FilterChain chain = (request, response) -> allowedRequests.incrementAndGet();

        for (int i = 0; i < 5; i++) {
            execute(filter, chain, "POST", "/api/auth/login", "203.0.113.20");
        }

        var otherAddress = execute(
                filter, chain, "POST", "/api/auth/login", "203.0.113.21"
        );

        assertEquals(200, otherAddress.getStatus());
        assertEquals(6, allowedRequests.get());
    }

    private static MockHttpServletResponse execute(
            RequestRateLimitFilter filter,
            FilterChain chain,
            String method,
            String path,
            String remoteAddress
    ) throws Exception {
        var request = new MockHttpServletRequest(method, path);
        request.setRemoteAddr(remoteAddress);
        var response = new MockHttpServletResponse();
        filter.doFilter(request, response, chain);
        return response;
    }
}
