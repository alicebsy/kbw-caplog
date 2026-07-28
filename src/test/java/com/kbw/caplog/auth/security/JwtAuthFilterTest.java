package com.kbw.caplog.auth.security;

import jakarta.servlet.DispatcherType;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

class JwtAuthFilterTest {

    private static final String STRONG_SECRET =
            "caplog-test-secret-that-is-longer-than-thirty-two-bytes";

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void filtersAsyncDispatches() {
        var filter = new JwtAuthFilter(new JwtUtil(STRONG_SECRET, 1, 14));

        assertFalse(filter.shouldNotFilterAsyncDispatch());
    }

    @Test
    void filtersErrorDispatches() {
        var filter = new JwtAuthFilter(new JwtUtil(STRONG_SECRET, 1, 14));

        assertFalse(filter.shouldNotFilterErrorDispatch());
    }

    @Test
    void restoresAuthenticationDuringAsyncDispatch() throws Exception {
        assertAuthenticationRestored(
                DispatcherType.ASYNC,
                "/api/ai/classify",
                "async-user@example.com"
        );
    }

    @Test
    void restoresAuthenticationDuringErrorDispatch() throws Exception {
        assertAuthenticationRestored(
                DispatcherType.ERROR,
                "/error",
                "error-user@example.com"
        );
    }

    private static void assertAuthenticationRestored(
            DispatcherType dispatcherType,
            String path,
            String subject
    ) throws Exception {
        var jwtUtil = new JwtUtil(STRONG_SECRET, 1, 14);
        var filter = new JwtAuthFilter(jwtUtil);
        var request = new MockHttpServletRequest("POST", path);
        request.setDispatcherType(dispatcherType);
        request.addHeader(
                "Authorization",
                "Bearer " + jwtUtil.generateAccessToken(subject)
        );
        var authenticatedSubject = new AtomicReference<String>();

        filter.doFilter(
                request,
                new MockHttpServletResponse(),
                (ignoredRequest, ignoredResponse) -> {
                    var authentication = SecurityContextHolder.getContext().getAuthentication();
                    authenticatedSubject.set(authentication == null ? null : authentication.getName());
                }
        );

        assertEquals(subject, authenticatedSubject.get());
    }
}
