package com.kbw.caplog.auth.security;

import org.springframework.http.HttpMethod;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;

/**
 * Spring Security 전역 설정
 * - /api/auth/**: 인증 없이 허용 (로그인, 회원가입, refresh 등)
 * - 그 외: JWT Bearer 토큰 필요
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final RequestRateLimitFilter requestRateLimitFilter;

    public SecurityConfig(
            JwtAuthFilter jwtAuthFilter,
            RequestRateLimitFilter requestRateLimitFilter
    ) {
        this.jwtAuthFilter = jwtAuthFilter;
        this.requestRateLimitFilter = requestRateLimitFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // REST API 기본 설정
                .csrf(csrf -> csrf.disable()) // 세션/폼로그인 안 쓰므로 CSFR 비활성
                .cors(Customizer.withDefaults())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // 세션을 생성/사용하지 않겠다는 Stateless
                .httpBasic(basic -> basic.disable()) // 브라우저 기본 인증 팝업 비활성
                .formLogin(login -> login.disable()) // 폼 로그인(스프링 제공 로그인 페이지) 비활성

                // 인가 규칙 (어떤 URL을 누구에게 열어줄지 )
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.PUT, "/api/auth/password").authenticated() // 비밀번호 변경은 JWT 필요
                        .requestMatchers("/api/auth/**").permitAll() // 로그인/회원가입/refresh/logout은 인증 없이 허용

                        .anyRequest().authenticated()   // 그 외는 인증 필요
                )

                // 인증이 없거나 만료된 요청은 401로 답합니다.
                // 기본값은 403인데, iOS 클라이언트는 401에서만 토큰을 갱신하고 재시도합니다.
                // 그래서 액세스 토큰이 만료되면 앱이 로그인 상태인 채로 모든 요청이 막혀
                // "최신 카드를 불러오지 못했다"는 화면에서 회복하지 못했습니다.
                .exceptionHandling(handling -> handling
                        .authenticationEntryPoint((request, response, authException) ->
                                response.sendError(HttpServletResponse.SC_UNAUTHORIZED))
                        .accessDeniedHandler((request, response, deniedException) ->
                                response.sendError(HttpServletResponse.SC_FORBIDDEN))
                )

                // 필터 체인에 JWT 필터 삽입
                // UsernamePasswordAuthenticationFilter보다 앞에 둬야 헤더 토큰 먼저 검증
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
                // 사용자별 제한을 위해 JWT 인증 정보가 설정된 다음 실행
                .addFilterAfter(requestRateLimitFilter, JwtAuthFilter.class);


        return http.build(); // 이 빌드 결과가 실제로 동작하는 보안 체인
    }

    /**
     * 두 인증 필터는 Spring Security 체인 안에서만 실행해야 한다.
     * 서블릿 컨테이너가 자동 등록하면 필터가 두 번 실행되고 실행 순서도 달라진다.
     */
    @Bean
    public FilterRegistrationBean<JwtAuthFilter> disableJwtFilterAutoRegistration(
            JwtAuthFilter filter
    ) {
        FilterRegistrationBean<JwtAuthFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public FilterRegistrationBean<RequestRateLimitFilter> disableRateLimitFilterAutoRegistration(
            RequestRateLimitFilter filter
    ) {
        FilterRegistrationBean<RequestRateLimitFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    // BCrypt 해시 인코더: 비밀번호를 안전하게 저장(해시 + 솔트)
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
