package com.kbw.caplog.recommendation.repository;

/**
 * 근접 추천 결과 Projection 인터페이스
 * (네이티브 쿼리 결과를 DTO로 매핑)
 */
public interface NearbyProjection {
    Long getId();
    String getTitle();
    String getSummary();
    String getPlaceName();
    String getAddress();
    Double getLat();
    Double getLng();
    String getImageUrl();
    Double getDistanceMeters();
}