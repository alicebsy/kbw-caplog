package com.kbw.caplog.ai.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AiClassifyRequest(
        @NotBlank
        @Size(max = 30_000)
        String prompt
) {
}
