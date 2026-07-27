package com.kbw.caplog.screenshot.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Map;
import java.util.UUID;

@Component
public class ScreenshotStorage {

    private static final Map<String, String> ALLOWED_TYPES = Map.of(
            "image/jpeg", ".jpg",
            "image/png", ".png"
    );

    private final Path uploadRoot;
    private final long maxFileSize;

    public ScreenshotStorage(
            @Value("${caplog.storage.upload-dir:./data/uploads}") String uploadDir,
            @Value("${caplog.storage.max-file-size:10485760}") long maxFileSize
    ) {
        this.uploadRoot = Path.of(uploadDir).toAbsolutePath().normalize();
        this.maxFileSize = maxFileSize;
    }

    public StoredImage store(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("이미지 파일이 필요합니다.");
        }
        if (file.getSize() > maxFileSize) {
            throw new IllegalArgumentException("이미지는 10MB 이하여야 합니다.");
        }

        String contentType = file.getContentType();
        String extension = ALLOWED_TYPES.get(contentType);
        if (extension == null) {
            throw new IllegalArgumentException("JPEG 또는 PNG 이미지만 업로드할 수 있습니다.");
        }

        byte[] bytes = file.getBytes();
        if (ImageIO.read(new ByteArrayInputStream(bytes)) == null) {
            throw new IllegalArgumentException("손상되었거나 유효하지 않은 이미지입니다.");
        }

        Files.createDirectories(uploadRoot);
        String storageKey = UUID.randomUUID() + extension;
        Path destination = resolveSafely(storageKey);
        Files.write(destination, bytes, StandardOpenOption.CREATE_NEW);
        return new StoredImage(storageKey, contentType, bytes.length);
    }

    public Resource load(String storageKey) throws IOException {
        Path path = resolveSafely(storageKey);
        Resource resource = new UrlResource(path.toUri());
        if (!resource.exists() || !resource.isReadable()) {
            throw new IOException("저장된 이미지 파일을 찾을 수 없습니다.");
        }
        return resource;
    }

    public void deleteQuietly(String storageKey) {
        try {
            Files.deleteIfExists(resolveSafely(storageKey));
        } catch (IOException ignored) {
            // DB 저장 실패를 원래 예외로 보고하기 위해 정리 실패는 무시한다.
        }
    }

    private Path resolveSafely(String storageKey) {
        if (storageKey == null || storageKey.isBlank()) {
            throw new IllegalArgumentException("잘못된 저장 키입니다.");
        }
        Path resolved = uploadRoot.resolve(storageKey).normalize();
        if (!resolved.startsWith(uploadRoot)) {
            throw new IllegalArgumentException("허용되지 않은 파일 경로입니다.");
        }
        return resolved;
    }

    public record StoredImage(String storageKey, String contentType, long sizeBytes) {
    }
}
