package com.kbw.caplog;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 프로젝트 실행 시작점. @SpringBootApplication 기준으로
 * com.kbw.caplog 하위 패키지를 컴포넌트 스캔.
 */
@SpringBootApplication
public class CaplogApplication {
    public static void main(String[] args) {
        SpringApplication.run(CaplogApplication.class, args);
    }
}