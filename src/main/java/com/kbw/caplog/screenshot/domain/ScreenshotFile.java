package com.kbw.caplog.screenshot.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "screenshot_file")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScreenshotFile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "file_name", length = 255)
    private String fileName;

    @Column(name = "file_url", length = 512)
    private String fileUrl;

    // 기존 DB 행과의 무중단 마이그레이션을 위해 nullable로 두되 신규 업로드는 항상 채운다.
    @Column(name = "storage_key", unique = true, length = 80)
    private String storageKey;

    @Column(name = "content_type", length = 40)
    private String contentType;

    @Column(name = "size_bytes")
    private Long sizeBytes;

    @Column(name = "uploaded_at")
    private LocalDateTime uploadedAt;
}
