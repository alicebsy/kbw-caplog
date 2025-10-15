package com.kbw.caplog.recommendation.dto;

import com.kbw.caplog.recommendation.repository.NearbyProjection;

/**
 * 근접 추천 응답 DTO
 */
public record NearbyResponse(
        Long id,
        String title,
        String summary,
        String placeName,
        String address,
        Double lat,
        Double lng,
        String imageUrl,
        Double distanceMeters
) {
    public static NearbyResponse from(NearbyProjection p) {
        return new NearbyResponse(
                p.getId(), p.getTitle(), p.getSummary(),
                p.getPlaceName(), p.getAddress(),
                p.getLat(), p.getLng(), p.getImageUrl(),
                p.getDistanceMeters()
        );
    }
}