package com.kbw.caplog.screenshot.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.kbw.caplog.screenshot.domain.ScreenshotFile;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Date;

@Getter
@Builder
public class ScreenshotItemDto {

    private String id;
    private String thumbnailUrl;
    private String title;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", timezone = "UTC")
    private Date createdAt;

    public static ScreenshotItemDto from(ScreenshotFile f, String baseUrl) {
        String url = f.getFileUrl();
        if (url != null && url.startsWith("/") && baseUrl != null) {
            url = baseUrl.replaceAll("/$", "") + url;
        }
        if (url == null || url.isBlank()) {
            url = (baseUrl != null ? baseUrl : "http://localhost:8080") + "/placeholder.png";
        }
        LocalDateTime at = f.getUploadedAt() != null ? f.getUploadedAt() : LocalDateTime.now();
        return ScreenshotItemDto.builder()
                .id(String.valueOf(f.getId()))
                .thumbnailUrl(url)
                .title(f.getFileName())
                .createdAt(Date.from(at.atZone(ZoneId.systemDefault()).toInstant()))
                .build();
    }
}
