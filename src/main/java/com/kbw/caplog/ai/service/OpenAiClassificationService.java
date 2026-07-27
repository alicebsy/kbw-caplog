package com.kbw.caplog.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.kbw.caplog.ai.dto.AiClassifyResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.TimeoutException;

import static org.springframework.http.HttpStatus.BAD_GATEWAY;
import static org.springframework.http.HttpStatus.GATEWAY_TIMEOUT;
import static org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE;

@Service
public class OpenAiClassificationService {

    private static final String SYSTEM_INSTRUCTIONS =
            "스크린샷 OCR 텍스트를 사용자가 지정한 기준으로 분류하세요. "
                    + "응답은 설명이나 마크다운 없이 JSON 객체만 출력하세요.";

    private final WebClient webClient;
    private final String apiKey;
    private final String model;

    public OpenAiClassificationService(
            WebClient.Builder webClientBuilder,
            @Value("${openai.api-key:}") String apiKey,
            @Value("${openai.model:gpt-4o-mini}") String model
    ) {
        this.webClient = webClientBuilder
                .baseUrl("https://api.openai.com")
                .build();
        this.apiKey = apiKey;
        this.model = model;
    }

    public Mono<AiClassifyResponse> classify(String prompt) {
        if (apiKey == null || apiKey.isBlank()) {
            return Mono.error(new ResponseStatusException(
                    SERVICE_UNAVAILABLE, "OPENAI_API_KEY가 설정되지 않았습니다."));
        }

        Map<String, Object> requestBody = Map.of(
                "model", model,
                "instructions", SYSTEM_INSTRUCTIONS,
                "input", prompt
        );

        return webClient.post()
                .uri("/v1/responses")
                .headers(headers -> headers.setBearerAuth(apiKey))
                .bodyValue(requestBody)
                .retrieve()
                .onStatus(HttpStatusCode::isError, response ->
                        response.bodyToMono(String.class)
                                .defaultIfEmpty("")
                                .map(ignored -> new ResponseStatusException(
                                        BAD_GATEWAY, "OpenAI 요청에 실패했습니다.")))
                .bodyToMono(JsonNode.class)
                .map(OpenAiClassificationService::parseResponse)
                .timeout(Duration.ofSeconds(90))
                .onErrorMap(TimeoutException.class, ignored ->
                        new ResponseStatusException(GATEWAY_TIMEOUT, "OpenAI 응답 시간이 초과됐습니다."));
    }

    static AiClassifyResponse parseResponse(JsonNode root) {
        String content = "";
        for (JsonNode output : root.path("output")) {
            if (!"message".equals(output.path("type").asText())) continue;
            for (JsonNode part : output.path("content")) {
                if ("output_text".equals(part.path("type").asText())) {
                    content = part.path("text").asText("").trim();
                    if (!content.isEmpty()) break;
                }
            }
            if (!content.isEmpty()) break;
        }

        if (content.isEmpty()) {
            throw new ResponseStatusException(BAD_GATEWAY, "OpenAI 응답에 텍스트가 없습니다.");
        }
        int totalTokens = root.path("usage").path("total_tokens").asInt(0);
        return new AiClassifyResponse(content, totalTokens);
    }
}
