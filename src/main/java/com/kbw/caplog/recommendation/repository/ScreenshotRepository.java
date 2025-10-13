package com.kbw.caplog.recommendation.repository;

import com.kbw.caplog.recommendation.domain.Screenshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ScreenshotRepository extends JpaRepository<Screenshot, Long> {

    @Query(value = """
    SELECT 
      s.screenshot_id AS id,
      s.title AS title,
      s.summary AS summary,
      s.place_name AS placeName,
      s.address AS address,
      s.lat AS lat,
      s.lng AS lng,
      s.image_url AS imageUrl,
      (
        6371000 * ACOS(
          LEAST(1, GREATEST(-1,
            COS(RADIANS(:lat)) * COS(RADIANS(s.lat)) *
            COS(RADIANS(s.lng) - RADIANS(:lng)) +
            SIN(RADIANS(:lat)) * SIN(RADIANS(s.lat))
          ))
        )
      ) AS distanceMeters
    FROM screenshot s
    WHERE s.lat IS NOT NULL
      AND s.lng IS NOT NULL
      AND s.lat BETWEEN (:lat - (:radius/111320.0)) AND (:lat + (:radius/111320.0))
      AND s.lng BETWEEN (:lng - (:radius/111320.0)) AND (:lng + (:radius/111320.0))
    HAVING distanceMeters <= :radius
    ORDER BY distanceMeters
    LIMIT :limit
    """, nativeQuery = true)
    List<NearbyProjection> findNearby(
            @Param("lat") double lat,
            @Param("lng") double lng,
            @Param("radius") int radiusMeters,
            @Param("limit") int limit
    );
}