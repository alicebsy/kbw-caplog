package com.kbw.caplog;


import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;


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
}