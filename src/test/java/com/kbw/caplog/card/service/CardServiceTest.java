package com.kbw.caplog.card.service;

import com.kbw.caplog.card.dto.CreateCardRequest;
import com.kbw.caplog.recommendation.domain.Screenshot;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import com.kbw.caplog.recommendation.service.GeocodeService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CardServiceTest {

    @Test
    void normalizesLocationFieldsAndGeocodesNewPlaceCard() {
        ScreenshotRepository repository = mock(ScreenshotRepository.class);
        GeocodeService geocodeService = mock(GeocodeService.class);
        CardService service = new CardService(repository, geocodeService);
        when(repository.save(any(Screenshot.class))).thenAnswer(invocation -> {
            Screenshot screenshot = invocation.getArgument(0);
            screenshot.setId(42L);
            return screenshot;
        });

        CreateCardRequest request = new CreateCardRequest();
        request.setTitle("테스트 카페");
        request.setCategory("Info");
        request.setFields(Map.of(
                "place_name", "  테스트 카페  ",
                "address", " 서울시 테스트로 1 "
        ));

        service.createCard(7L, request);

        ArgumentCaptor<Screenshot> captor = ArgumentCaptor.forClass(Screenshot.class);
        verify(repository).save(captor.capture());
        assertEquals("테스트 카페", captor.getValue().getPlaceName());
        assertEquals("서울시 테스트로 1", captor.getValue().getAddress());
        verify(geocodeService).geocodeOne(42L, 7L);
    }
}
