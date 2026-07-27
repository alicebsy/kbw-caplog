package com.kbw.caplog.ai.dto;

public record VisionLabelResponse(
        String description,
        double confidence
) {
}
