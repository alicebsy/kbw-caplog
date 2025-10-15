package com.kbw.caplog.recommendation.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

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
}