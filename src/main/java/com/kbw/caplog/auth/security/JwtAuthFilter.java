package com.kbw.caplog.auth.security;

import com.kbw.caplog.auth.security.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
// 매 요청마다 토큰 검증
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        // 회원가입/로그인 요청은 JWT 검증 안 함
        String path = request.getRequestURI();
        if (path.startsWith("/api/auth")) {
            filterChain.doFilter(request, response);
            return;
        }

        // Authorization 헤더에서 "Bearer {token}" 형태를 기대
        String header = request.getHeader("Authorization");
        // 헤더가 없거나 잘못된 경우 그냥 다음 필터로 넘김
        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // "Bearer" 이후 실제 토큰만 추출
        String token = header.substring(7);
        try {
            // 토큰 검증 + 주체(subject, 여기서는 email) 꺼내기
            String email = jwtUtil.validateAndGetSubject(token);

            // security가 이해할 수 있는 Authentication 객체 만들기
            //  (principal=email, credentials=null, authorities=빈목록)
            UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(email, null, null);

            // 요청에 대한 부가정보(IP 등) 추가
            auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

            // 현재 스레드의 SecurityContext에 인증결과 저장
            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (Exception ignored) {
            // 토큰이 만료/위조/형식 오류 등 발생 시
            // 인증을 세팅하지 않고 그대로 다음 필터로 넘김
            // (여기서 response.sendError(400) 하지 않음!)
        }

        // 다음 필터로 넘김 (필수)
        filterChain.doFilter(request, response);
    }
}