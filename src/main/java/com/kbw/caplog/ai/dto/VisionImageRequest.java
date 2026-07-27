package com.kbw.caplog.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record VisionImageRequest(
        @NotBlank
        @Size(max = 14_000_000)
        String imageBase64
) {
}
