package com.kbw.caplog.card.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * 카드 응답 DTO (프론트엔드 Card 모델과 호환)
 * - Screenshot 엔티티를 프론트 Card 형식으로 매핑
 */
@Getter
@Builder
public class CardDto {

    /** 카드 고유 ID (UUID 문자열 형식, 프론트 호환용) */
    private String id;

    private String title;
    private String summary;

    /** 대분류: Info, Contents, Social, Log, Music/Art, Etc. */
    private String category;

    /** 소분류: 맛집, 카페, 쿠폰 등 */
    private String subcategory;

    private List<String> tags;
    private Map<String, String> fields;

    @JsonFormat(shape = JsonFormat.Shape.STRING, timezone = "UTC")
    private Instant createdAt;

    @JsonFormat(shape = JsonFormat.Shape.STRING, timezone = "UTC")
    private Instant updatedAt;

    private String thumbnailURL;
    private List<String> screenshotURLs;
}
