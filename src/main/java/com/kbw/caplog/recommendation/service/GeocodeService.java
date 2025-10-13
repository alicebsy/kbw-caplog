package com.kbw.caplog.recommendation.service;

import com.kbw.caplog.recommendation.domain.Screenshot;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class GeocodeService {

    private final ScreenshotRepository screenshotRepository;
    private final KakaoGeocodingClient kakao;

    @Value("${caplog.geocode.throttleMillis:250}")
    private long throttleMillis;

    /** 스크린샷 한 건 지오코딩 */
    @Transactional
    public boolean geocodeOne(Long screenshotId) {
        Screenshot s = screenshotRepository.findById(screenshotId)
                .orElseThrow(() -> new IllegalArgumentException("Screenshot not found: " + screenshotId));

        // 주소가 있으면 주소, 없으면 장소명 사용
        String query = (s.getAddress() != null && !s.getAddress().isBlank())
                ? s.getAddress() : s.getPlaceName();
        if (query == null || query.isBlank()) return false;

        s.setGeocodeAttempts(s.getGeocodeAttempts() == null ? 1 : s.getGeocodeAttempts() + 1);
        var pointOpt = kakao.geocode(query);

        if (pointOpt.isEmpty()) {
            s.setGeocodeStatus((short) 2); // 실패
            return false;
        }

        var p = pointOpt.get();
        s.setLat(p.lat());
        s.setLng(p.lng());
        s.setGeocodeStatus((short) 1); // 성공
        s.setGeocodeConfidence((short) 100);

        // JPA @Transactional → 자동 저장
        sleepQuiet(throttleMillis);
        return true;
    }

    private void sleepQuiet(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException ignored) {}
    }
}