package com.kbw.caplog.recommendation.service;

import com.kbw.caplog.recommendation.repository.NearbyProjection;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RecommendationServiceTest {

    @Test
    void scopesNearbyQueryToAuthenticatedUser() {
        ScreenshotRepository repository = mock(ScreenshotRepository.class);
        NearbyProjection projection = mock(NearbyProjection.class);
        when(projection.getPlaceName()).thenReturn("테스트 카페");
        when(projection.getAddress()).thenReturn("서울");
        when(repository.findNearby(42L, 37.5, 127.0, 1000, 15))
                .thenReturn(List.of(projection));

        RecommendationService service = new RecommendationService(repository);
        var result = service.findNearby(42L, 37.5, 127.0, 1000, 3);

        assertEquals(1, result.size());
        verify(repository).findNearby(42L, 37.5, 127.0, 1000, 15);
    }
}
