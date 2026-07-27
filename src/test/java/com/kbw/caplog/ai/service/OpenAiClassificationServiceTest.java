package com.kbw.caplog.ai.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class OpenAiClassificationServiceTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void parsesResponsesApiOutputTextAndUsage() throws Exception {
        var json = objectMapper.readTree("""
                {
                  "output": [{
                    "type": "message",
                    "content": [{"type": "output_text", "text": "{\\"category_main\\":\\"Info\\"}"}]
                  }],
                  "usage": {"total_tokens": 123}
                }
                """);

        var response = OpenAiClassificationService.parseResponse(json);

        assertEquals("{\"category_main\":\"Info\"}", response.content());
        assertEquals(123, response.totalTokens());
    }

    @Test
    void rejectsResponseWithoutOutputText() throws Exception {
        var json = objectMapper.readTree("""
                {"output": [], "usage": {"total_tokens": 0}}
                """);

        assertThrows(ResponseStatusException.class,
                () -> OpenAiClassificationService.parseResponse(json));
    }
}
