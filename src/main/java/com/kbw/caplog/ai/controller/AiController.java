package com.kbw.caplog.ai.controller;

import com.kbw.caplog.ai.dto.AiClassifyRequest;
import com.kbw.caplog.ai.dto.AiClassifyResponse;
import com.kbw.caplog.ai.dto.VisionImageRequest;
import com.kbw.caplog.ai.dto.VisionLabelsResponse;
import com.kbw.caplog.ai.dto.VisionTextResponse;
import com.kbw.caplog.ai.service.GoogleVisionService;
import com.kbw.caplog.ai.service.OpenAiClassificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiController {

    private final OpenAiClassificationService openAiClassificationService;
    private final GoogleVisionService googleVisionService;

    @PostMapping("/classify")
    public Mono<AiClassifyResponse> classify(@Valid @RequestBody AiClassifyRequest request) {
        return openAiClassificationService.classify(request.prompt());
    }

    @PostMapping("/vision/text")
    public Mono<VisionTextResponse> extractText(@Valid @RequestBody VisionImageRequest request) {
        return googleVisionService.extractText(request.imageBase64());
    }

    @PostMapping("/vision/labels")
    public Mono<VisionLabelsResponse> detectLabels(@Valid @RequestBody VisionImageRequest request) {
        return googleVisionService.detectLabels(request.imageBase64());
    }
}
