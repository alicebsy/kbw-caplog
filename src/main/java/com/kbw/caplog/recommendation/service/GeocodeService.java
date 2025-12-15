package com.kbw.caplog.recommendation.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kbw.caplog.recommendation.domain.Screenshot;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class GeocodeService {

    private final ScreenshotRepository repo;
    private final KakaoGeocodingClient kakao;
    private final ObjectMapper om = new ObjectMapper();

    /** 단건 지오코딩: 주소 먼저, 안되면 place_name 사용 */
    @Transactional
    public boolean geocodeOne(Long screenshotId) {
        Screenshot s = repo.findById(screenshotId).orElseThrow();

        if (s.getLat() != null && s.getLng() != null) return true;

        boolean success = false;

        if (s.getAddress() != null && !s.getAddress().isBlank()) {
            success = tryAddress(s);
        }

        if (!success && s.getPlaceName() != null && !s.getPlaceName().isBlank()) {
            success = tryKeyword(s);
        }

        s.setGeocodeAttempts(nullToZero(s.getGeocodeAttempts()) + 1);
        s.setGeocodeStatus((short) (success ? 1 : 2)); // 1 성공, 2 실패
        repo.save(s);
        return success;
    }

    private boolean tryAddress(Screenshot s) {
        try {
            String json = kakao.geocodeByAddress(s.getAddress().trim());
            JsonNode docs = om.readTree(json).path("documents");
            if (docs.isArray() && docs.size() > 0) {
                JsonNode first = docs.get(0);

                // 도로명 우선, 없으면 지번
                String y = first.path("road_address").path("y").asText(null);
                String x = first.path("road_address").path("x").asText(null);
                if (y == null || x == null) {
                    y = first.path("address").path("y").asText(null);
                    x = first.path("address").path("x").asText(null);
                }

                if (y != null && x != null) {
                    s.setLat(Double.valueOf(y));
                    s.setLng(Double.valueOf(x));
                    return true;
                }
            }
        } catch (Exception e) {
            System.out.println("⚠️ 주소 지오코딩 실패: " + e.getMessage());
        }
        return false;
    }

    private boolean tryKeyword(Screenshot s) {
        try {
            String json = kakao.geocodeByKeyword(s.getPlaceName().trim());
            JsonNode docs = om.readTree(json).path("documents");
            if (docs.isArray() && docs.size() > 0) {
                JsonNode first = docs.get(0);
                String y = first.path("y").asText(null);
                String x = first.path("x").asText(null);
                if (y != null && x != null) {
                    s.setLat(Double.valueOf(y));
                    s.setLng(Double.valueOf(x));

                    // 주소가 비어 있으면 keyword 결과의 도로명 주소 보완
                    if (isBlank(s.getAddress())) {
                        String addr = first.path("road_address_name").asText(null);
                        if (addr != null && !addr.isEmpty()) s.setAddress(addr);
                    }
                    return true;
                }
            }
        } catch (Exception e) {
            System.out.println("⚠️ 장소명 지오코딩 실패: " + e.getMessage());
        }
        return false;
    }

    private static boolean isBlank(String v) { return v == null || v.isBlank(); }
    private static int nullToZero(Integer v) { return v == null ? 0 : v; }
}