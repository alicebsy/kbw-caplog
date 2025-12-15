package com.kbw.caplog.recommendation.controller;

import com.kbw.caplog.recommendation.service.GeocodeService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/geocode")
@RequiredArgsConstructor
public class GeocodeController {

    private final GeocodeService geocodeService;

    @PostMapping("/{id}")
    public String geocodeOne(@PathVariable Long id) {
        return geocodeService.geocodeOne(id) ? "OK" : "NO_RESULT";
    }
}