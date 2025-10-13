package com.kbw.caplog.recommendation.service;

import com.kbw.caplog.recommendation.dto.NearbyResponse;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RecommendationService {

    private final ScreenshotRepository screenshotRepository;

    @Transactional(readOnly = true)
    public List<NearbyResponse> findNearby(double lat, double lng, int radiusMeters, int limit) {
        // UI는 최대 3장만 노출. 중복/유사 제거를 위해 내부 fetch는 살짝 여유
        int need = Math.min(limit, 3);
        int fetch = Math.max(need * 5, 10); // 10~15 정도 권장

        var rows = screenshotRepository.findNearby(lat, lng, radiusMeters, fetch);

        // 장소 중복 제거: placeName + address 기준 간단 normalize
        var seen = new java.util.LinkedHashSet<String>();
        var result = new java.util.ArrayList<NearbyResponse>(need);

        for (var p : rows) {
            String key = ((p.getPlaceName() == null ? "" : p.getPlaceName().trim()) + "|" +
                    (p.getAddress() == null ? "" : p.getAddress().trim()))
                    .toLowerCase();
            if (seen.add(key)) {
                result.add(NearbyResponse.from(p));
                if (result.size() == need) break;
            }
        }
        return result;
    }
}