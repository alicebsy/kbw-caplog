package com.kbw.caplog.screenshot.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ScreenshotStorageTest {

    @TempDir
    Path tempDir;

    @Test
    void storesValidImageWithGeneratedName() throws Exception {
        ScreenshotStorage storage = new ScreenshotStorage(tempDir.toString(), 1024 * 1024);
        MockMultipartFile image = new MockMultipartFile(
                "file", "../../unsafe.jpg", "image/jpeg", jpegBytes());

        ScreenshotStorage.StoredImage stored = storage.store(image);

        assertTrue(stored.storageKey().matches("[0-9a-f-]{36}\\.jpg"));
        assertTrue(storage.load(stored.storageKey()).exists());
    }

    @Test
    void rejectsNonImageAndOversizedFile() {
        ScreenshotStorage storage = new ScreenshotStorage(tempDir.toString(), 4);
        MockMultipartFile text = new MockMultipartFile(
                "file", "payload.txt", "text/plain", "hello".getBytes());
        MockMultipartFile tooLarge = new MockMultipartFile(
                "file", "image.jpg", "image/jpeg", new byte[5]);

        assertThrows(IllegalArgumentException.class, () -> storage.store(text));
        assertThrows(IllegalArgumentException.class, () -> storage.store(tooLarge));
    }

    @Test
    void rejectsPathTraversalOnLoad() {
        ScreenshotStorage storage = new ScreenshotStorage(tempDir.toString(), 1024);

        assertThrows(IllegalArgumentException.class, () -> storage.load("../secret"));
    }

    private static byte[] jpegBytes() throws Exception {
        BufferedImage image = new BufferedImage(2, 2, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", output);
        return output.toByteArray();
    }
}
