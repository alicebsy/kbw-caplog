package com.kbw.caplog.card.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kbw.caplog.card.dto.CardDto;
import com.kbw.caplog.card.dto.CreateCardRequest;
import com.kbw.caplog.recommendation.domain.Screenshot;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import com.kbw.caplog.recommendation.service.GeocodeService;
import lombok.RequiredArgsConstructor;
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
    private final GeocodeService geocodeService;
    private final ObjectMapper objectMapper;

    /**
     * 스크린샷 AI 분류 결과를 DB에 저장 (iOS에서 카드 생성 시 호출)
     */
    public CardDto createCard(Long userNo, CreateCardRequest req) {
        Screenshot s = new Screenshot();
        s.setUserNo(userNo);
        applyRequest(s, req);
        s.setGeocodeStatus((short) 0);
        s.setGeocodeAttempts(0);
        s.setGeocodeConfidence((short) 0);
        Screenshot saved = screenshotRepository.save(s);
        if ((saved.getPlaceName() != null && !saved.getPlaceName().isBlank())
                || (saved.getAddress() != null && !saved.getAddress().isBlank())) {
            try {
                geocodeService.geocodeOne(saved.getId(), userNo);
            } catch (RuntimeException error) {
                System.out.println("⚠️ 카드 위치 변환 예약 실패: " + error.getMessage());
            }
        }
        return toCardDto(saved);
    }

    /** 현재 사용자가 소유한 카드만 수정합니다. */
    public CardDto updateCard(Long userNo, String externalId, CreateCardRequest req) {
        Long screenshotId = externalIdToLong(externalId);
        Screenshot screenshot = screenshotRepository.findByIdAndUserNo(screenshotId, userNo)
                .orElseThrow(() -> new IllegalArgumentException("Card not found"));

        String previousPlaceName = screenshot.getPlaceName();
        String previousAddress = screenshot.getAddress();
        applyRequest(screenshot, req);
        boolean locationChanged = !Objects.equals(previousPlaceName, screenshot.getPlaceName())
                || !Objects.equals(previousAddress, screenshot.getAddress());
        if (locationChanged) {
            screenshot.setLat(null);
            screenshot.setLng(null);
            screenshot.setGeocodeStatus((short) 0);
            screenshot.setGeocodeAttempts(0);
            screenshot.setGeocodeConfidence((short) 0);
        }

        Screenshot saved = screenshotRepository.save(screenshot);
        if (locationChanged && hasLocationText(saved)) {
            try {
                geocodeService.geocodeOne(saved.getId(), userNo);
            } catch (RuntimeException error) {
                System.out.println("⚠️ 카드 위치 재변환 예약 실패: " + error.getMessage());
            }
        }
        return toCardDto(saved);
    }

    /** 현재 사용자가 소유한 카드만 삭제합니다. */
    public void deleteCard(Long userNo, String externalId) {
        Long screenshotId = externalIdToLong(externalId);
        Screenshot screenshot = screenshotRepository.findByIdAndUserNo(screenshotId, userNo)
                .orElseThrow(() -> new IllegalArgumentException("Card not found"));
        screenshotRepository.delete(screenshot);
    }

    private void applyRequest(Screenshot screenshot, CreateCardRequest req) {
        screenshot.setCategoryId(categoryNameToId(req.getCategory()));
        screenshot.setTitle(req.getTitle() != null && !req.getTitle().isBlank()
                ? truncate(req.getTitle().trim(), 120)
                : "제목 없음");
        screenshot.setSummary(req.getSummary() != null ? truncate(req.getSummary(), 255) : null);
        screenshot.setSubcategory(req.getSubcategory() != null
                ? truncate(req.getSubcategory().trim(), 80)
                : null);
        screenshot.setTagsJson(writeJson(req.getTags() != null ? req.getTags() : List.of()));
        screenshot.setFieldsJson(writeJson(req.getFields() != null ? req.getFields() : Map.of()));
        screenshot.setPlaceName(req.getFields() != null
                ? truncate(firstNonBlank(req.getFields(), "장소명", "place_name", "가게명"), 120)
                : null);
        screenshot.setAddress(req.getFields() != null
                ? truncate(firstNonBlank(req.getFields(), "주소", "address"), 255)
                : null);
        // 개인정보가 포함될 수 있는 원본 이미지와 기기 전용 경로는 서버에 저장하지 않는다.
        screenshot.setImageUrl(null);
    }

    private static boolean hasLocationText(Screenshot screenshot) {
        return (screenshot.getPlaceName() != null && !screenshot.getPlaceName().isBlank())
                || (screenshot.getAddress() != null && !screenshot.getAddress().isBlank());
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException error) {
            throw new IllegalArgumentException("Invalid card data", error);
        }
    }

    private <T> T readJson(String json, TypeReference<T> type, T fallback) {
        if (json == null || json.isBlank()) return fallback;
        try {
            return objectMapper.readValue(json, type);
        } catch (JsonProcessingException error) {
            return fallback;
        }
    }

    private static String truncate(String value, int maxLen) {
        if (value == null) return null;
        return value.length() <= maxLen ? value : value.substring(0, maxLen);
    }

    private static String firstNonBlank(Map<String, String> fields, String... keys) {
        for (String key : keys) {
            String value = fields.get(key);
            if (value != null && !value.isBlank()) return value.trim();
        }
        return null;
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

    /** 채팅 공유용: 외부 UUID 형식 카드 ID를 현재 사용자의 카드로 검증하고 스냅샷을 반환합니다. */
    public CardDto findOwnedCardByExternalId(Long userNo, String externalId) {
        Long screenshotId = externalIdToLong(externalId);
        Screenshot screenshot = screenshotRepository.findByIdAndUserNo(screenshotId, userNo)
                .orElseThrow(() -> new IllegalArgumentException("Card not found"));
        return toCardDto(screenshot);
    }

    /**
     * Screenshot → CardDto 변환
     * - 프론트 Card 모델 필드에 맞춤
     */
    private CardDto toCardDto(Screenshot s) {
        // id를 UUID 문자열 형식으로 변환 (프론트 호환)
        String uuidStr = longToUuidString(s.getId());

        String category = mapCategoryId(s.getCategoryId());
        String subcategory = s.getSubcategory() != null && !s.getSubcategory().isBlank()
                ? s.getSubcategory()
                : mapSubcategory(category, s.getPlaceName());

        Map<String, String> fields = new HashMap<>(readJson(
                s.getFieldsJson(),
                new TypeReference<Map<String, String>>() {},
                Map.of()
        ));
        if (s.getPlaceName() != null) fields.put("장소명", s.getPlaceName());
        if (s.getAddress() != null) fields.put("주소", s.getAddress());

        List<String> tags = new ArrayList<>(readJson(
                s.getTagsJson(),
                new TypeReference<List<String>>() {},
                List.of()
        ));
        if (s.getTagsJson() == null) {
            if (s.getPlaceName() != null) tags.add(s.getPlaceName());
            if (s.getSummary() != null && !s.getSummary().isBlank()) {
                tags.addAll(Arrays.asList(s.getSummary().split("\\s+")));
            }
        }

        return CardDto.builder()
                .id(uuidStr)
                .title(s.getTitle() != null ? s.getTitle() : s.getPlaceName() != null ? s.getPlaceName() : "제목 없음")
                .summary(s.getSummary() != null ? s.getSummary() : "")
                .category(category)
                .subcategory(subcategory)
                .tags(tags)
                .fields(fields)
                .createdAt(s.getCreatedAt() != null ? s.getCreatedAt() : Instant.now())
                .updatedAt(s.getUpdatedAt() != null ? s.getUpdatedAt() : Instant.now())
                .thumbnailURL(null)
                .screenshotURLs(List.of())
                .build();
    }

    /** Long id → UUID 형식 문자열 (00000000-0000-0000-0000-{12자리 hex}) */
    private static String longToUuidString(Long id) {
        if (id == null) return UUID.randomUUID().toString();
        return String.format("00000000-0000-0000-0000-%012x", id);
    }

    private static Long externalIdToLong(String externalId) {
        try {
            UUID uuid = UUID.fromString(externalId);
            long id = uuid.getLeastSignificantBits();
            if (uuid.getMostSignificantBits() != 0 || id <= 0) {
                throw new IllegalArgumentException("Invalid card id");
            }
            return id;
        } catch (IllegalArgumentException error) {
            throw new IllegalArgumentException("Invalid card id", error);
        }
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
