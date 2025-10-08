package com.kbw.caplog.auth.security;

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

@Configuration
@EnableWebSecurity
// 전역 보안 설정
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // REST API 기본 설정
                .csrf(csrf -> csrf.disable()) // 세션/폼로그인 안 쓰므로 CSFR 비활성
                .cors(Customizer.withDefaults())    // 필요시 별도 CORS Bean으로 허용 출처 지정 가능
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                                                                         // 세션을 생성/사용하지 않겠다는 Stateless
                .httpBasic(basic -> basic.disable()) // 브라우저 기본 인증 팝업 비활성
                .formLogin(login -> login.disable()) // 폼 로그인(스프링 제공 로그인 페이지) 비활성

                // 인가 규칙 (어떤 URL을 누구에게 열어줄지 )
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll() // 로그인/회원가입은 모두에게 공개
                        .anyRequest().authenticated()   // 그 외는 인증 필요
                )

                // 필터 체인에 JWT 필터 삽입
                // UsernamePasswordAuthenticationFilter보다 앞에 둬야 헤더 토큰 먼저 검증
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);


        return http.build(); // 이 빌드 결과가 실제로 동작하는 보안 체인
    }

    // BCrypt 해시 인코더: 비밀번호를 안전하게 저장(해시 + 솔트)
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}