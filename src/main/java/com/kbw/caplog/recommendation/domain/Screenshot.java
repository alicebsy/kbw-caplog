package com.kbw.caplog.recommendation.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "screenshot")
@Getter @Setter
public class Screenshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "screenshot_id")
    private Long id;

    @Column(name = "user_no")
    private Long userNo;

    @Column(name = "category_id")
    private Long categoryId;

    @Column(length = 120)
    private String title;

    @Column(length = 255)
    private String summary;

    @Column(length = 80)
    private String subcategory;

    @Lob
    @Column(name = "tags_json", columnDefinition = "TEXT")
    private String tagsJson;

    @Lob
    @Column(name = "fields_json", columnDefinition = "TEXT")
    private String fieldsJson;

    @Column(name = "place_name", length = 120)
    private String placeName;

    @Column(length = 255)
    private String address;

    private Double lat;
    private Double lng;

    @Column(name = "image_url", length = 255)
    private String imageUrl;

    @Column(name = "geocode_status")
    private Short geocodeStatus;

    @Column(name = "geocode_attempts")
    private Integer geocodeAttempts;

    @Column(name = "geocode_confidence")
    private Short geocodeConfidence;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}
