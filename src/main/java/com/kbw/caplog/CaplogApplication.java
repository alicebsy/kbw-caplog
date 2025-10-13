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
    // ★ 테스트 끝났으면 이 Bean은 지워도 됩니다.
    @Bean
    CommandLineRunner testKakao(com.kbw.caplog.recommendation.service.KakaoGeocodingClient kakao) {
        return args -> {
            // 1) 주소로 테스트
            String r1 = kakao.geocodeByAddress("경기도 고양시 일산동구 하늘마을로 76");
            System.out.println("addr result = " + r1);

            // 2) 키워드로 테스트
            String r2 = kakao.geocodeByKeyword("센트럴 더 포레");
            System.out.println("keyword result = " + r2);
        };
    }
}