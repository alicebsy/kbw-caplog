package com.kbw.caplog.ai.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class GoogleVisionServiceTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void parsesTextDetectionResponse() throws Exception {
        var json = objectMapper.readTree("""
                {
                  "responses": [{
                    "textAnnotations": [{"description": "쿠폰 번호 1234"}]
                  }]
                }
                """);

        var response = GoogleVisionService.parseText(json);

        assertEquals("쿠폰 번호 1234", response.text());
    }

    @Test
    void parsesLabelDetectionResponse() throws Exception {
        var json = objectMapper.readTree("""
                {
                  "responses": [{
                    "labelAnnotations": [
                      {"description": "Food", "score": 0.95},
                      {"description": "Receipt", "score": 0.7}
                    ]
                  }]
                }
                """);

        var response = GoogleVisionService.parseLabels(json);

        assertEquals(2, response.labels().size());
        assertEquals("Food", response.labels().get(0).description());
        assertEquals(0.95, response.labels().get(0).confidence());
    }

    @Test
    void rejectsProviderErrorWithoutLeakingDetails() throws Exception {
        var json = objectMapper.readTree("""
                {
                  "responses": [{
                    "error": {"message": "provider secret detail"}
                  }]
                }
                """);

        var error = assertThrows(
                ResponseStatusException.class,
                () -> GoogleVisionService.parseLabels(json)
        );

        assertEquals("Google Vision 이미지 분석에 실패했습니다.", error.getReason());
    }
}
