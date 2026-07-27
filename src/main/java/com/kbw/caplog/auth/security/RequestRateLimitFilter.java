package com.kbw.caplog.auth.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicLong;

@Component
public class RequestRateLimitFilter extends OncePerRequestFilter {

    private static final String TOO_MANY_REQUESTS_BODY =
            "{\"message\":\"요청이 너무 많습니다. 잠시 후 다시 시도해주세요.\"}";

    private static final List<Policy> POLICIES = List.of(
            new Policy("login", "POST", "/api/auth/login", 5, 60, Subject.IP, false),
            new Policy("signup", "POST", "/api/auth/signup", 3, 600, Subject.IP, false),
            new Policy("refresh", "POST", "/api/auth/refresh", 10, 60, Subject.IP, false),
            new Policy("upload", "POST", "/api/screenshots/upload", 10, 60, Subject.USER, false),
            new Policy("ai-classify", "POST", "/api/ai/classify", 20, 60, Subject.USER, false),
            new Policy("ai-vision", "POST", "/api/ai/vision/", 10, 60, Subject.USER, true)
    );

    private final ConcurrentMap<LimitKey, WindowCounter> counters = new ConcurrentHashMap<>();
    private final AtomicLong requestCount = new AtomicLong();
    private final boolean trustForwardedHeaders;
    private final Clock clock;

    public RequestRateLimitFilter(
            @Value("${caplog.security.trust-forwarded-headers:false}") boolean trustForwardedHeaders
    ) {
        this(trustForwardedHeaders, Clock.systemUTC());
    }

    RequestRateLimitFilter(boolean trustForwardedHeaders, Clock clock) {
        this.trustForwardedHeaders = trustForwardedHeaders;
        this.clock = clock;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        Policy policy = policyFor(request);
        if (policy == null) {
            filterChain.doFilter(request, response);
            return;
        }

        long now = clock.millis();
        if ((requestCount.incrementAndGet() & 255) == 0) {
            counters.entrySet().removeIf(entry -> entry.getValue().isExpired(now));
        }

        String identity = policy.subject() == Subject.IP
                ? clientIp(request)
                : authenticatedUserOrIp(request);
        LimitKey key = new LimitKey(policy.name(), identity);
        Decision decision = counters
                .computeIfAbsent(key, ignored -> new WindowCounter(now))
                .tryAcquire(now, policy.limit(), policy.windowSeconds());

        if (!decision.allowed()) {
            response.setStatus(429);
            response.setContentType("application/json");
            response.setCharacterEncoding(StandardCharsets.UTF_8.name());
            response.setHeader("Cache-Control", "no-store");
            response.setHeader("Retry-After", Long.toString(decision.retryAfterSeconds()));
            response.getWriter().write(TOO_MANY_REQUESTS_BODY);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private Policy policyFor(HttpServletRequest request) {
        String method = request.getMethod();
        String path = request.getRequestURI();
        for (Policy policy : POLICIES) {
            boolean pathMatches = policy.prefixMatch()
                    ? path.startsWith(policy.path())
                    : path.equals(policy.path());
            if (policy.method().equals(method) && pathMatches) {
                return policy;
            }
        }
        return null;
    }

    private String authenticatedUserOrIp(HttpServletRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null
                && authentication.isAuthenticated()
                && authentication.getName() != null
                && !authentication.getName().isBlank()) {
            return "user:" + authentication.getName();
        }
        return "ip:" + clientIp(request);
    }

    private String clientIp(HttpServletRequest request) {
        if (trustForwardedHeaders) {
            String forwardedFor = request.getHeader("X-Forwarded-For");
            if (forwardedFor != null && !forwardedFor.isBlank()) {
                String first = forwardedFor.split(",", 2)[0].trim();
                if (!first.isEmpty() && first.length() <= 128) {
                    return first;
                }
            }
        }
        String remoteAddress = request.getRemoteAddr();
        return remoteAddress == null || remoteAddress.isBlank() ? "unknown" : remoteAddress;
    }

    private enum Subject {
        IP,
        USER
    }

    private record Policy(
            String name,
            String method,
            String path,
            int limit,
            long windowSeconds,
            Subject subject,
            boolean prefixMatch
    ) {
    }

    private record LimitKey(String policy, String identity) {
    }

    private record Decision(boolean allowed, long retryAfterSeconds) {
        static Decision permit() {
            return new Decision(true, 0);
        }

        static Decision reject(long retryAfterSeconds) {
            return new Decision(false, retryAfterSeconds);
        }
    }

    private static final class WindowCounter {
        private long windowStartedAt;
        private long windowMilliseconds;
        private int count;

        private WindowCounter(long now) {
            this.windowStartedAt = now;
        }

        private synchronized Decision tryAcquire(long now, int limit, long windowSeconds) {
            long requestedWindowMilliseconds = windowSeconds * 1_000;
            long elapsed = now - windowStartedAt;
            if (elapsed < 0
                    || windowMilliseconds != requestedWindowMilliseconds
                    || elapsed >= requestedWindowMilliseconds) {
                windowStartedAt = now;
                windowMilliseconds = requestedWindowMilliseconds;
                count = 0;
                elapsed = 0;
            }

            if (count >= limit) {
                long remainingMilliseconds = Math.max(1, requestedWindowMilliseconds - elapsed);
                long retryAfterSeconds = Math.max(1, (remainingMilliseconds + 999) / 1_000);
                return Decision.reject(retryAfterSeconds);
            }

            count++;
            return Decision.permit();
        }

        private synchronized boolean isExpired(long now) {
            return windowMilliseconds > 0
                    && now - windowStartedAt >= windowMilliseconds;
        }
    }
}
