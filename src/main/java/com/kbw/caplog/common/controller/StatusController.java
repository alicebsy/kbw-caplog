package com.kbw.caplog.common.controller;

import com.kbw.caplog.common.dto.ApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Caplog 상태/정보 확인용 엔드포인트.
 * DB 불필요
 * 서버 기동 여부를 쉽게 확인 가능
 */
@RestController
@RequestMapping("/api/caplog")
public class StatusController {

    @Value("${spring.application.name:caplog}")
    private String appName;

    // 가장 가벼운 핑
    @GetMapping("/ping")
    public ApiResponse<String> ping() {
        return ApiResponse.success("pong", "caplog backend is alive");
    }

    // 간단한 앱 정보(이름, 현재 시간)
    @GetMapping("/info")
    public ApiResponse<Map<String, Object>> info() {
        Map<String, Object> data = new HashMap<>();
        data.put("app", appName);
        data.put("time", OffsetDateTime.now().toString());
        return ApiResponse.success(data, "caplog backend info");
    }
}