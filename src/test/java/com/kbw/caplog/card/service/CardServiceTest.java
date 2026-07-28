package com.kbw.caplog.card.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.kbw.caplog.card.dto.CardDto;
import com.kbw.caplog.card.dto.CreateCardRequest;
import com.kbw.caplog.recommendation.domain.Screenshot;
import com.kbw.caplog.recommendation.repository.ScreenshotRepository;
import com.kbw.caplog.recommendation.service.GeocodeService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CardServiceTest {

    @Test
    void normalizesLocationFieldsAndGeocodesNewPlaceCard() {
        ScreenshotRepository repository = mock(ScreenshotRepository.class);
        GeocodeService geocodeService = mock(GeocodeService.class);
        CardService service = new CardService(repository, geocodeService, objectMapper());
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

    @Test
    void updatesEveryEditableFieldOnOwnedCard() {
        ScreenshotRepository repository = mock(ScreenshotRepository.class);
        GeocodeService geocodeService = mock(GeocodeService.class);
        CardService service = new CardService(repository, geocodeService, objectMapper());
        Screenshot screenshot = new Screenshot();
        screenshot.setId(42L);
        screenshot.setUserNo(7L);
        screenshot.setPlaceName("이전 장소");
        screenshot.setCreatedAt(Instant.parse("2026-07-01T00:00:00Z"));
        when(repository.findByIdAndUserNo(42L, 7L)).thenReturn(Optional.of(screenshot));
        when(repository.save(screenshot)).thenReturn(screenshot);

        CreateCardRequest request = new CreateCardRequest();
        request.setTitle("수정된 카드");
        request.setSummary("수정된 설명");
        request.setCategory("Social");
        request.setSubcategory("친구");
        request.setTags(List.of("약속", "주말"));
        request.setFields(Map.of("장소명", "새 장소", "주소", "서울시 테스트로 2"));
        request.setThumbnailURL("https://example.com/card.jpg");

        CardDto updated = service.updateCard(
                7L,
                "00000000-0000-0000-0000-00000000002a",
                request
        );

        assertEquals("수정된 카드", updated.getTitle());
        assertEquals("Social", updated.getCategory());
        assertEquals("친구", updated.getSubcategory());
        assertEquals(List.of("약속", "주말"), updated.getTags());
        assertEquals("새 장소", updated.getFields().get("장소명"));
        assertEquals("서울시 테스트로 2", updated.getFields().get("주소"));
        assertEquals(Instant.parse("2026-07-01T00:00:00Z"), updated.getCreatedAt());
        verify(repository).save(screenshot);
        verify(geocodeService).geocodeOne(42L, 7L);
    }

    @Test
    void doesNotDeleteCardOwnedByAnotherUser() {
        ScreenshotRepository repository = mock(ScreenshotRepository.class);
        GeocodeService geocodeService = mock(GeocodeService.class);
        CardService service = new CardService(repository, geocodeService, objectMapper());
        when(repository.findByIdAndUserNo(42L, 7L)).thenReturn(Optional.empty());

        assertThrows(
                IllegalArgumentException.class,
                () -> service.deleteCard(7L, "00000000-0000-0000-0000-00000000002a")
        );

        verify(repository, never()).delete(any(Screenshot.class));
    }

    private static ObjectMapper objectMapper() {
        return new ObjectMapper().findAndRegisterModules();
    }
}
