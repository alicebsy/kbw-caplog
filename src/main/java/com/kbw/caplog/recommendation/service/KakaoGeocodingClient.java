package com.kbw.caplog.recommendation.service;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Component
public class KakaoGeocodingClient {

    private final WebClient client;

    public KakaoGeocodingClient() {
        String apiKey = System.getenv("KAKAO_REST_API_KEY"); // 환경변수
        this.client = WebClient.builder()
                .baseUrl("https://dapi.kakao.com")
                .defaultHeader(HttpHeaders.AUTHORIZATION, "KakaoAK " + apiKey)
                .build();
    }

    /** 주소 문자열로 좌표 조회 -> JSON(String) 반환 */
    public String geocodeByAddress(String address) {
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