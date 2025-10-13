package com.kbw.caplog.recommendation.controller;

import com.kbw.caplog.recommendation.service.KakaoGeocodingClient;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequiredArgsConstructor
public class GeocodeDebugController {

    private final KakaoGeocodingClient kakao;

    @GetMapping("/api/debug/geocode")
    public Object debug(@RequestParam String query) {
        return kakao.geocode(query)
                .<Object>map(p -> Map.of("lat", p.lat(), "lng", p.lng()))
                .orElseGet(() -> Map.of("message", "no_result"));
    }
}