package com.kbw.caplog.screenshot.controller;

import com.kbw.caplog.screenshot.domain.ScreenshotFile;
import com.kbw.caplog.screenshot.dto.UploadResponseDto;
import com.kbw.caplog.screenshot.service.ScreenshotService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * ScreenshotController
 * - 클라이언트(iOS, 웹 등)에서 업로드 요청을 처리하는 REST API
 * - multipart/form-data 형식의 파일 업로드 지원
 */
@RestController
@RequestMapping("/api/screenshots")
@RequiredArgsConstructor
public class ScreenshotController {

    private final ScreenshotService screenshotService;

    /**
     * 스크린샷 업로드 엔드포인트
     * @param file 업로드된 이미지 파일
     * @param userId 사용자 ID
     * @return 업로드 결과 DTO
     */
    @PostMapping("/upload")
    public ResponseEntity<UploadResponseDto> uploadScreenshot(
            @RequestParam("file") MultipartFile file,
            @RequestParam("userId") Long userId
    ) {
        // ✅ [추가] 업로드 요청 로그
        System.out.println("[DEBUG] 업로드 요청 도착: userId=" + userId + ", file=" + file.getOriginalFilename());
        System.out.println("[DEBUG] ContentType: " + file.getContentType());

        try {
            // 1. 파일 이름 추출
            String fileName = file.getOriginalFilename();

            // 2. 실제 업로드 경로 설정 (현재는 임시 값)
            //    나중에 AWS S3나 Firebase Storage로 교체 가능
            String fileUrl = "/uploads/" + fileName;

            // 3. DB에 스크린샷 메타데이터 저장
            ScreenshotFile saved = screenshotService.saveScreenshot(userId, fileName, fileUrl);

            // 4. 응답 DTO 생성
            UploadResponseDto response = new UploadResponseDto(saved.getId(), saved.getFileUrl());

            // ✅ [추가] 성공 로그
            System.out.println("[DEBUG] 업로드 완료: id=" + saved.getId() + ", url=" + saved.getFileUrl());

            // 5. 결과 반환
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            // ✅ [추가] 예외 발생 시 콘솔 확인
            System.err.println("[ERROR] 업로드 실패: " + e.getMessage());
            e.printStackTrace();

            // 500 내부 서버 에러 반환
            return ResponseEntity.internalServerError().build();
        }
    }
}