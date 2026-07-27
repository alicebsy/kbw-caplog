package com.kbw.caplog.recommendation.controller;

import com.kbw.caplog.recommendation.service.GeocodeService;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/geocode")
@RequiredArgsConstructor
public class GeocodeController {

    private final GeocodeService geocodeService;
    private final UserRepository userRepository;

    @PostMapping("/{id}")
    public String geocodeOne(Authentication auth, @PathVariable Long id) {
        Long userNo = resolveUserNo(auth);
        return geocodeService.geocodeOne(id, userNo) ? "OK" : "NO_RESULT";
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
