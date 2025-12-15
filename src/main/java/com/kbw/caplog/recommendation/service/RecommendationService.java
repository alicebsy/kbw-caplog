package com.kbw.caplog.recommendation.service;

import com.kbw.caplog.recommendation.dto.NearbyResponse;
import com.kbw.caplog.recommendation.repository.NearbyProjection;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RecommendationService {

    private final ScreenshotRepository repo;

    /**
     * 거리 기반 추천
     * - 기본 반경 내에서 장소 부족하면 반경 확장
     * - 최대 3개 카드 추천
     */
    @Transactional(readOnly = true)
    public List<NearbyResponse> findNearby(double lat, double lng, int radiusMeters, int limit) {
        int need = Math.min(limit, 3);
        List<NearbyProjection> acc = new ArrayList<>();

        // 여러 반경 시도: 1km → 1.5km → 3km → 5km
        int[] radii = {radiusMeters, 1500, 3000, 5000};

        for (int r : radii) {
            if (acc.size() >= need) break;
            var rows = repo.findNearby(lat, lng, r, need * 5);
            acc.addAll(rows);
        }

        // 중복 제거 + 최대 need개만
        var seen = new LinkedHashSet<String>();
        var result = new ArrayList<NearbyResponse>();

        for (var p : acc) {
            String key = ((p.getPlaceName() == null ? "" : p.getPlaceName().trim()) + "|" +
                    (p.getAddress() == null ? "" : p.getAddress().trim())).toLowerCase();

            if (seen.add(key)) {
                result.add(NearbyResponse.from(p));
                if (result.size() == need) break;
            }
        }

        return result;
    }
}