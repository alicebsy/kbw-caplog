package com.kbw.caplog;

import com.kbw.caplog.recommendation.service.KakaoGeocodingClient;  // 테스트용 추가
import org.springframework.boot.CommandLineRunner;                      // 테스트용 추가
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;  // 테스트용 추가


/**
    프로젝트 실행 시작점! -> 메인 클래스
    @SpringBootApplication 어노테이션이 달린 클래스 기준으로
    같은 패키지(com.kbw.caplog)와 그 하위 패키지(login, signup, screenshot 등)를 자동으로 스캔함
**/

@SpringBootApplication
public class CaplogApplication {
    public static void main(String[] args) {
        // Spring Boot 애플리케이션 실행 (내장 Tomcat 서버 시작)
        SpringApplication.run(CaplogApplication.class, args);
    }
    // ✅ 서버 기동 직후 1회 실행되는 테스트 훅
    @Bean
    CommandLineRunner testKakao(KakaoGeocodingClient kakao) {
        return args -> {
            var point = kakao.geocode("경기도 고양시 일산동구 하늘마을로 76");
            if (point.isPresent()) {
                System.out.println("✅ lat=" + point.get().lat() + ", lng=" + point.get().lng());
            } else {
                System.out.println("⚠️ no_result");
            }
        };
    }
}