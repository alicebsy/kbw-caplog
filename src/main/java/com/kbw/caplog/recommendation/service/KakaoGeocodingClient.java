package com.kbw.caplog.recommendation.service;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Optional;

@Component
public class KakaoGeocodingClient {

    private final WebClient client;

    public KakaoGeocodingClient() {
        String apiKey = System.getenv("KAKAO_REST_API_KEY");
        this.client = WebClient.builder()
                .baseUrl("https://dapi.kakao.com")
                .defaultHeader(HttpHeaders.AUTHORIZATION, "KakaoAK " + apiKey)
                .build();
    }

    /** 주소/장소명 → 위도(lat), 경도(lng) */
    public Optional<GeoPoint> geocode(String query) {
        KakaoAddrResponse resp = client.get()
                .uri(b -> b.path("/v2/local/search/address.json")
                        .queryParam("query", query)
                        .queryParam("size", 1)
                        .build())
                .retrieve()
                .onStatus(HttpStatusCode::is4xxClientError,
                        r -> r.bodyToMono(String.class)
                                .flatMap(b -> Mono.error(new RuntimeException("Kakao 4xx: " + b))))
                .onStatus(HttpStatusCode::is5xxServerError,
                        r -> r.bodyToMono(String.class)
                                .flatMap(b -> Mono.error(new RuntimeException("Kakao 5xx: " + b))))
                .bodyToMono(KakaoAddrResponse.class)
                .block();

        if (resp == null || resp.getDocuments() == null || resp.getDocuments().isEmpty()) {
            return Optional.empty();
        }

        // 첫 번째 결과만 사용
        KakaoAddrResponse.Document doc = resp.getDocuments().get(0);
        double lat = Double.parseDouble(doc.getY());
        double lng = Double.parseDouble(doc.getX());
        return Optional.of(new GeoPoint(lat, lng));
    }

    /* ===== Kakao 응답 DTO ===== */
    public static class KakaoAddrResponse {
        private List<Document> documents;
        public List<Document> getDocuments() { return documents; }

        public static class Document {
            private String x;  // 경도
            private String y;  // 위도
            public String getX() { return x; }
            public String getY() { return y; }
        }
    }

    /* ===== 좌표 값 객체 ===== */
    public record GeoPoint(double lat, double lng) {}
}