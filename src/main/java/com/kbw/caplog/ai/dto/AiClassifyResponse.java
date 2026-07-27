package com.kbw.caplog.ai.dto;

public record AiClassifyResponse(
        String content,
        int totalTokens
) {
}
