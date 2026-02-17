package com.kbw.caplog.card.service;

import com.kbw.caplog.card.dto.CardDto;
import com.kbw.caplog.card.dto.CreateCardRequest;
import com.kbw.caplog.recommendation.domain.Screenshot;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 카드 비즈니스 로직
 * - Screenshot 엔티티를 프론트 Card 형식으로 변환
 */
@Service
@RequiredArgsConstructor
public class CardService {

    private final ScreenshotRepository screenshotRepository;

    @Value("${app.baseUrl:http://localhost:8080}")
    private String baseUrl;

    /**
     * 스크린샷 AI 분류 결과를 DB에 저장 (iOS에서 카드 생성 시 호출)
     */
    public CardDto createCard(Long userNo, CreateCardRequest req) {
        Screenshot s = new Screenshot();
        s.setUserNo(userNo);
        s.setCategoryId(categoryNameToId(req.getCategory()));
        s.setTitle(req.getTitle() != null ? truncate(req.getTitle(), 120) : "제목 없음");
        s.setSummary(req.getSummary() != null ? truncate(req.getSummary(), 255) : null);
        s.setPlaceName(req.getFields() != null ? truncate(req.getFields().get("장소명"), 120) : null);
        s.setAddress(req.getFields() != null ? truncate(req.getFields().get("주소"), 255) : null);
        String imgUrl = req.getThumbnailURL();
        if ((imgUrl == null || imgUrl.isBlank()) && req.getScreenshotURLs() != null && !req.getScreenshotURLs().isEmpty()) {
            imgUrl = req.getScreenshotURLs().get(0);
        }
        s.setImageUrl(imgUrl != null ? truncate(imgUrl, 255) : null);
        s.setGeocodeStatus((short) 0);
        s.setGeocodeAttempts(0);
        s.setGeocodeConfidence((short) 0);
        Screenshot saved = screenshotRepository.save(s);
        return toCardDto(saved);
    }

    private static String truncate(String value, int maxLen) {
        if (value == null) return null;
        return value.length() <= maxLen ? value : value.substring(0, maxLen);
    }

    /** category 이름 → categoryId (toCardDto의 %6 매핑과 맞춤: 0=Info, 1=Contents, …) */
    private static Long categoryNameToId(String category) {
        if (category == null || category.isBlank()) return 5L;
        return switch (category) {
            case "Info" -> 0L;
            case "Contents" -> 1L;
            case "Social" -> 2L;
            case "Log" -> 3L;
            case "Music/Art" -> 4L;
            default -> 5L;
        };
    }

    /**
     * 유저별 카드 목록 조회 (Screenshot 기반)
     * - categoryId → FolderCategory 매핑 (1=Info, 2=Contents, 3=Social 등)
     */
    public List<CardDto> findCardsByUserNo(Long userNo, int limit) {
        List<Screenshot> screenshots = screenshotRepository.findByUserNoOrderByIdDesc(userNo);
        if (limit > 0 && screenshots.size() > limit) {
            screenshots = screenshots.subList(0, limit);
        }
        return screenshots.stream()
                .map(this::toCardDto)
                .collect(Collectors.toList());
    }

    /**
     * Screenshot → CardDto 변환
     * - 프론트 Card 모델 필드에 맞춤
     */
    private CardDto toCardDto(Screenshot s) {
        // id를 UUID 문자열 형식으로 변환 (프론트 호환)
        String uuidStr = longToUuidString(s.getId());

        String category = mapCategoryId(s.getCategoryId());
        String subcategory = mapSubcategory(category, s.getPlaceName());

        Map<String, String> fields = new HashMap<>();
        if (s.getPlaceName() != null) fields.put("장소명", s.getPlaceName());
        if (s.getAddress() != null) fields.put("주소", s.getAddress());
        if (s.getTitle() != null) fields.put("가게명", s.getTitle());

        List<String> tags = new ArrayList<>();
        if (s.getPlaceName() != null) tags.add(s.getPlaceName());
        if (s.getSummary() != null && !s.getSummary().isBlank()) {
            tags.addAll(Arrays.asList(s.getSummary().split("\\s+")));
        }

        String imgUrl = s.getImageUrl();
        if (imgUrl != null && imgUrl.startsWith("/")) {
            imgUrl = baseUrl.replaceAll("/$", "") + imgUrl;
        }
        List<String> screenshotURLs = imgUrl != null ? List.of(imgUrl) : List.of();

        return CardDto.builder()
                .id(uuidStr)
                .title(s.getTitle() != null ? s.getTitle() : s.getPlaceName() != null ? s.getPlaceName() : "제목 없음")
                .summary(s.getSummary() != null ? s.getSummary() : "")
                .category(category)
                .subcategory(subcategory)
                .tags(tags)
                .fields(fields)
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .thumbnailURL(imgUrl)
                .screenshotURLs(screenshotURLs)
                .build();
    }

    /** Long id → UUID 형식 문자열 (00000000-0000-0000-0000-{12자리 hex}) */
    private static String longToUuidString(Long id) {
        if (id == null) return UUID.randomUUID().toString();
        return String.format("00000000-0000-0000-0000-%012x", id);
    }

    /** categoryId → FolderCategory rawValue */
    private static String mapCategoryId(Long categoryId) {
        if (categoryId == null) return "Etc.";
        return switch ((int) (categoryId % 6)) {
            case 0 -> "Info";
            case 1 -> "Contents";
            case 2 -> "Social";
            case 3 -> "Log";
            case 4 -> "Music/Art";
            default -> "Etc.";
        };
    }

    private static String mapSubcategory(String category, String placeName) {
        if ("Info".equals(category) && placeName != null) return "맛집";
        return "기타";
    }
}
