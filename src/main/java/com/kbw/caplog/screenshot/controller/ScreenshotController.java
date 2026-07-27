package com.kbw.caplog.screenshot.controller;

import com.kbw.caplog.screenshot.domain.ScreenshotFile;
import com.kbw.caplog.screenshot.dto.PagedScreenshotResponse;
import com.kbw.caplog.screenshot.dto.ScreenshotItemDto;
import com.kbw.caplog.screenshot.dto.UploadResponseDto;
import com.kbw.caplog.screenshot.service.ScreenshotService;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.CacheControl;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 스크린샷 API
 * - POST /api/screenshots/upload: 인증 사용자의 이미지 업로드
 * - GET /api/screenshots: 내 스크린샷 목록 (JWT Bearer 필요)
 */
@RestController
@RequestMapping("/api/screenshots")
@RequiredArgsConstructor
public class ScreenshotController {

    private final ScreenshotService screenshotService;
    private final UserRepository userRepository;

    @Value("${app.baseUrl:http://localhost:8080}")
    private String baseUrl;

    /**
     * 스크린샷 업로드 엔드포인트
     * @param file 업로드된 이미지 파일
     * @return 업로드 결과 DTO
     */
    @PostMapping("/upload")
    public ResponseEntity<UploadResponseDto> uploadScreenshot(
            Authentication auth,
            @RequestParam("file") MultipartFile file
    ) {
        User user = resolveUser(auth);
        if (user == null) return ResponseEntity.status(401).build();
        try {
            ScreenshotFile saved = screenshotService.storeScreenshot(user.getUserNo(), file);
            String fileUrl = baseUrl.replaceAll("/$", "") + saved.getFileUrl();
            UploadResponseDto response = new UploadResponseDto(saved.getId(), fileUrl);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/{id}/content")
    public ResponseEntity<Resource> getScreenshotContent(
            Authentication auth,
            @PathVariable Long id
    ) {
        User user = resolveUser(auth);
        if (user == null) return ResponseEntity.status(401).build();
        try {
            ScreenshotService.ScreenshotContent content =
                    screenshotService.loadOwnedScreenshot(id, user.getUserNo());
            MediaType mediaType = MediaType.parseMediaType(content.metadata().getContentType());
            ContentDisposition disposition = ContentDisposition.inline()
                    .filename(content.metadata().getFileName(), StandardCharsets.UTF_8)
                    .build();
            return ResponseEntity.ok()
                    .cacheControl(CacheControl.noStore())
                    .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
                    .contentType(mediaType)
                    .contentLength(content.metadata().getSizeBytes())
                    .body(content.resource());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 내 스크린샷 목록 조회 (인증 필요)
     */
    @GetMapping
    public ResponseEntity<PagedScreenshotResponse> listMyScreenshots(
            Authentication auth,
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "20") int size
    ) {
        User user = resolveUser(auth);
        if (user == null) {
            return ResponseEntity.status(401).build();
        }
        List<ScreenshotItemDto> items = screenshotService.findByUserId(user.getUserNo())
                .stream()
                .map(f -> ScreenshotItemDto.from(f, baseUrl))
                .collect(Collectors.toList());
        return ResponseEntity.ok(new PagedScreenshotResponse(items, null));
    }

    private User resolveUser(Authentication auth) {
        String email = auth != null ? auth.getName() : null;
        if (email == null || email.isBlank()) return null;
        return userRepository.findByEmail(email).orElse(null);
    }
}
