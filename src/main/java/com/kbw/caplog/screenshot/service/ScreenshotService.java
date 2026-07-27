package com.kbw.caplog.screenshot.service;

import com.kbw.caplog.screenshot.domain.ScreenshotFile;
import com.kbw.caplog.screenshot.repository.ScreenshotFileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.core.io.Resource;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

/**
 * ScreenshotService
 * - 비즈니스 로직 담당
 * - 파일 정보 저장 및 DB insert
 * - 나중에 S3 업로드 등으로 확장 가능
 */
@Service
@RequiredArgsConstructor
public class ScreenshotService {

    private final ScreenshotFileRepository screenshotFileRepository;
    private final ScreenshotStorage screenshotStorage;

    /**
     * 스크린샷 메타데이터를 DB에 저장
     * @param userId 업로드한 사용자 ID
     * @param fileName 파일명
     * @param fileUrl 파일 경로(URL)
     * @return 저장된 ScreenshotFile 객체
     */
    @Transactional
    public ScreenshotFile storeScreenshot(Long userId, MultipartFile file) throws IOException {
        ScreenshotStorage.StoredImage stored = screenshotStorage.store(file);
        try {
            ScreenshotFile screenshot = ScreenshotFile.builder()
                    .userId(userId)
                    .fileName(safeDisplayName(file.getOriginalFilename()))
                    .storageKey(stored.storageKey())
                    .contentType(stored.contentType())
                    .sizeBytes(stored.sizeBytes())
                    .uploadedAt(LocalDateTime.now())
                    .build();
            ScreenshotFile saved = screenshotFileRepository.save(screenshot);
            saved.setFileUrl("/api/screenshots/" + saved.getId() + "/content");
            return screenshotFileRepository.save(saved);
        } catch (RuntimeException e) {
            screenshotStorage.deleteQuietly(stored.storageKey());
            throw e;
        }
    }

    public List<ScreenshotFile> findByUserId(Long userId) {
        return screenshotFileRepository.findByUserIdOrderByUploadedAtDesc(userId);
    }

    public ScreenshotContent loadOwnedScreenshot(Long id, Long userId) throws IOException {
        ScreenshotFile screenshot = screenshotFileRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new IllegalArgumentException("스크린샷을 찾을 수 없습니다."));
        return new ScreenshotContent(screenshot, screenshotStorage.load(screenshot.getStorageKey()));
    }

    private static String safeDisplayName(String originalName) {
        if (originalName == null || originalName.isBlank()) {
            return "screenshot";
        }
        String normalized = originalName.replace('\\', '/');
        String fileName = normalized.substring(normalized.lastIndexOf('/') + 1)
                .replaceAll("[\\p{Cntrl}]", "")
                .trim();
        if (fileName.isBlank()) return "screenshot";
        return fileName.length() <= 255 ? fileName : fileName.substring(fileName.length() - 255);
    }

    public record ScreenshotContent(ScreenshotFile metadata, Resource resource) {
    }
}
