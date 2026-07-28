package com.kbw.caplog.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.kbw.caplog.ai.dto.VisionLabelResponse;
import com.kbw.caplog.ai.dto.VisionLabelsResponse;
import com.kbw.caplog.ai.dto.VisionTextResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ResponseStatusException;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeoutException;

import static org.springframework.http.HttpStatus.BAD_GATEWAY;
import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.GATEWAY_TIMEOUT;
import static org.springframework.http.HttpStatus.PAYLOAD_TOO_LARGE;
import static org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE;

@Service
public class GoogleVisionService {

    private static final Logger log =
            LoggerFactory.getLogger(GoogleVisionService.class);

    private static final int MAX_IMAGE_BYTES = 10 * 1024 * 1024;

    private final WebClient webClient;
    private final String apiKey;

    public GoogleVisionService(
            WebClient.Builder webClientBuilder,
            @Value("${google.vision.api-key:}") String apiKey
    ) {
        this.webClient = webClientBuilder
                .baseUrl("https://vision.googleapis.com")
                .build();
        this.apiKey = apiKey;
    }

    public Mono<VisionTextResponse> extractText(String imageBase64) {
        return annotate(imageBase64, "TEXT_DETECTION", 1, true)
                .map(GoogleVisionService::parseText);
    }

    public Mono<VisionLabelsResponse> detectLabels(String imageBase64) {
        return annotate(imageBase64, "LABEL_DETECTION", 10, false)
                .map(GoogleVisionService::parseLabels);
    }

    private Mono<JsonNode> annotate(
            String imageBase64,
            String featureType,
            int maxResults,
            boolean includeLanguageHints
    ) {
        if (apiKey == null || apiKey.isBlank()) {
            return Mono.error(new ResponseStatusException(
                    SERVICE_UNAVAILABLE, "GOOGLE_VISION_API_KEY가 설정되지 않았습니다."));
        }

        validateImage(imageBase64);

        Map<String, Object> request = new HashMap<>();
        request.put("image", Map.of("content", imageBase64));
        request.put("features", List.of(Map.of(
                "type", featureType,
                "maxResults", maxResults
        )));
        if (includeLanguageHints) {
            request.put("imageContext", Map.of("languageHints", List.of("ko", "en")));
        }

        return webClient.post()
                .uri(uriBuilder -> uriBuilder
                        .path("/v1/images:annotate")
                        .queryParam("key", apiKey)
                        .build())
                .bodyValue(Map.of("requests", List.of(request)))
                .retrieve()
                .onStatus(HttpStatusCode::isError, response -> {
                    log.warn("Google Vision upstream request failed with status {}",
                            response.statusCode().value());
                    return response.releaseBody().then(Mono.error(
                            new ResponseStatusException(
                                    BAD_GATEWAY, "Google Vision 요청에 실패했습니다.")
                    ));
                })
                .bodyToMono(JsonNode.class)
                .timeout(Duration.ofSeconds(60))
                .onErrorMap(TimeoutException.class, ignored ->
                        new ResponseStatusException(
                                GATEWAY_TIMEOUT, "Google Vision 응답 시간이 초과됐습니다."));
    }

    static VisionTextResponse parseText(JsonNode root) {
        JsonNode response = firstResponse(root);
        JsonNode annotations = response.path("textAnnotations");
        String text = annotations.isArray() && !annotations.isEmpty()
                ? annotations.get(0).path("description").asText("")
                : "";
        return new VisionTextResponse(text);
    }

    static VisionLabelsResponse parseLabels(JsonNode root) {
        JsonNode response = firstResponse(root);
        List<VisionLabelResponse> labels = new ArrayList<>();
        for (JsonNode annotation : response.path("labelAnnotations")) {
            String description = annotation.path("description").asText("").trim();
            if (!description.isEmpty()) {
                labels.add(new VisionLabelResponse(
                        description,
                        annotation.path("score").asDouble(0.0)
                ));
            }
        }
        return new VisionLabelsResponse(List.copyOf(labels));
    }

    private static JsonNode firstResponse(JsonNode root) {
        JsonNode responses = root.path("responses");
        if (!responses.isArray() || responses.isEmpty()) {
            throw new ResponseStatusException(
                    BAD_GATEWAY, "Google Vision 응답 형식이 올바르지 않습니다.");
        }

        JsonNode response = responses.get(0);
        if (!response.path("error").isMissingNode()) {
            throw new ResponseStatusException(
                    BAD_GATEWAY, "Google Vision 이미지 분석에 실패했습니다.");
        }
        return response;
    }

    private static void validateImage(String imageBase64) {
        final byte[] decoded;
        try {
            decoded = Base64.getDecoder().decode(imageBase64);
        } catch (IllegalArgumentException ignored) {
            throw new ResponseStatusException(BAD_REQUEST, "이미지 데이터가 올바르지 않습니다.");
        }

        if (decoded.length > MAX_IMAGE_BYTES) {
            throw new ResponseStatusException(PAYLOAD_TOO_LARGE, "이미지는 최대 10MB까지 허용됩니다.");
        }
        if (!isJpeg(decoded) && !isPng(decoded)) {
            throw new ResponseStatusException(BAD_REQUEST, "JPEG 또는 PNG 이미지만 허용됩니다.");
        }
    }

    private static boolean isJpeg(byte[] bytes) {
        return bytes.length >= 3
                && (bytes[0] & 0xff) == 0xff
                && (bytes[1] & 0xff) == 0xd8
                && (bytes[2] & 0xff) == 0xff;
    }

    private static boolean isPng(byte[] bytes) {
        byte[] signature = {
                (byte) 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a
        };
        if (bytes.length < signature.length) return false;
        for (int i = 0; i < signature.length; i++) {
            if (bytes[i] != signature[i]) return false;
        }
        return true;
    }
}
