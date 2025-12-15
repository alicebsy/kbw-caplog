package com.kbw.caplog.screenshot.repository;

import com.kbw.caplog.screenshot.domain.ScreenshotFile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/**
 * ScreenshotFileRepository
 * - ScreenshotFile 엔티티용 기본 CRUD 기능 제공
 * - 유저별 스크린샷 조회 기능 포함
 */
@Repository
public interface ScreenshotFileRepository extends JpaRepository<ScreenshotFile, Long> {

    // userId로 스크린샷 조회 (최신순 정렬 등은 나중에 추가 가능)
    List<ScreenshotFile> findByUserId(Long userId);
}