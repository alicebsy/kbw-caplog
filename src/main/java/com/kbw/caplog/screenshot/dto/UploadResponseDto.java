package com.kbw.caplog.screenshot.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * UploadResponseDto
 * - 업로드 후 클라이언트로 반환할 데이터 구조
 * - 추후 추가 필드(업로드 시간 등) 확장 가능
 */
@Getter
@AllArgsConstructor
public class UploadResponseDto {
    private Long id;        // 저장된 스크린샷 ID
    private String fileUrl; // 접근 가능한 URL
}