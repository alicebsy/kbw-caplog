package com.kbw.caplog.recommendation.controller;

import com.kbw.caplog.recommendation.dto.NearbyResponse;
import com.kbw.caplog.recommendation.service.RecommendationService;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/recommend")
@RequiredArgsConstructor
public class RecommendationController {

    private final RecommendationService service;
    private final UserRepository userRepository;

    @GetMapping("/nearby")
    public List<NearbyResponse> nearby(
            Authentication auth,
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "1000") int radiusMeters,
            @RequestParam(defaultValue = "3") int limit  // 기본 3
    ) {
        // sanity clamp
        int r = Math.max(50, Math.min(radiusMeters, 20_000)); // 50m ~ 20km
        int l = Math.max(1, Math.min(limit, 200));
        Long userNo = resolveUserNo(auth);
        return service.findNearby(userNo, lat, lng, r, l);
    }

    private Long resolveUserNo(Authentication auth) {
        if (auth == null || auth.getName() == null || auth.getName().isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
        return userRepository.findByEmail(auth.getName())
                .map(User::getUserNo)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
    }
}
