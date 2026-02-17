package com.kbw.caplog.recommendation.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Component
public class KakaoGeocodingClient {

    private final WebClient client;
    private final String apiKey;

    public KakaoGeocodingClient(
            @Value("${kakao.restApiKey:}") String keyFromProp
    ) {
        String key = keyFromProp;
        if (key == null || key.isBlank()) {
            key = System.getenv("KAKAO_REST_API_KEY");
        }
        if (key == null || key.isBlank()) {
            key = System.getProperty("kakao.restApiKey");
        }
        this.apiKey = (key != null && !key.isBlank()) ? key.trim() : null;

        if (this.apiKey != null) {
            this.client = WebClient.builder()
                    .baseUrl("https://dapi.kakao.com")
                    .defaultHeader(HttpHeaders.AUTHORIZATION, "KakaoAK " + this.apiKey)
                    .build();
        } else {
            this.client = null;
            // 키 없이 기동 가능 (지오코딩 호출 시에만 에러)
        }
    }


    /** 주소 문자열로 좌표 조회 -> JSON(String) 반환 */
    public String geocodeByAddress(String address) {
        if (client == null) {
            throw new IllegalStateException("KAKAO_REST_API_KEY(또는 kakao.restApiKey)가 설정되지 않았습니다. application.yml 또는 환경변수 KAKAO_REST_API_KEY를 설정하세요.");
        }
        return client.get()
                .uri(b -> b.path("/v2/local/search/address.json")
                        .queryParam("query", address)
                        .queryParam("size", 1)
                        .build())
                .retrieve()
                .onStatus(HttpStatusCode::is4xxClientError,
                        resp -> resp.bodyToMono(String.class)
                                .flatMap(b -> Mono.error(new RuntimeException("Kakao 4xx: " + b))))
                .onStatus(HttpStatusCode::is5xxServerError,
                        resp -> resp.bodyToMono(String.class)
                                .flatMap(b -> Mono.error(new RuntimeException("Kakao 5xx: " + b))))
                .bodyToMono(String.class)
                .block();
    }

    /** 장소명(키워드)로 좌표 조회 -> JSON(String) 반환 */
    public String geocodeByKeyword(String keyword) {
        if (client == null) {
            throw new IllegalStateException("KAKAO_REST_API_KEY(또는 kakao.restApiKey)가 설정되지 않았습니다.");
        }
        return client.get()
                .uri(b -> b.path("/v2/local/search/keyword.json")
                        .queryParam("query", keyword)
                        .queryParam("size", 1)
                        .build())
                .retrieve()
                .onStatus(HttpStatusCode::is4xxClientError,
                        resp -> resp.bodyToMono(String.class)
                                .flatMap(b -> Mono.error(new RuntimeException("Kakao 4xx: " + b))))
                .onStatus(HttpStatusCode::is5xxServerError,
                        resp -> resp.bodyToMono(String.class)
                                .flatMap(b -> Mono.error(new RuntimeException("Kakao 5xx: " + b))))
                .bodyToMono(String.class)
                .block();
    }
}