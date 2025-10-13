package com.kbw.caplog.recommendation.controller;

import com.kbw.caplog.recommendation.dto.NearbyResponse;
import com.kbw.caplog.recommendation.service.RecommendationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recommend")
@RequiredArgsConstructor
public class RecommendationController {

    private final RecommendationService service;

    @GetMapping("/nearby")
    public List<NearbyResponse> nearby(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "1000") int radiusMeters,
            @RequestParam(defaultValue = "3") int limit  // 기본 3
    ) {
        // sanity clamp
        int r = Math.max(50, Math.min(radiusMeters, 20_000)); // 50m ~ 20km
        int l = Math.max(1, Math.min(limit, 200));
        return service.findNearby(lat, lng, r, l);
    }
}