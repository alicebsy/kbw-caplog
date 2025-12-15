package com.kbw.caplog.screenshot.service;

import com.kbw.caplog.screenshot.domain.ScreenshotFile;
import com.kbw.caplog.screenshot.repository.ScreenshotFileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

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

    /**
     * 스크린샷 메타데이터를 DB에 저장
     * @param userId 업로드한 사용자 ID
     * @param fileName 파일명
     * @param fileUrl 파일 경로(URL)
     * @return 저장된 ScreenshotFile 객체
     */
    public ScreenshotFile saveScreenshot(Long userId, String fileName, String fileUrl) {
        ScreenshotFile screenshot = ScreenshotFile.builder()
                .userId(userId)
                .fileName(fileName)
                .fileUrl(fileUrl)
                .uploadedAt(LocalDateTime.now())
                .build();

        return screenshotFileRepository.save(screenshot);
    }
}