package com.kbw.caplog.ai.controller;

import com.kbw.caplog.ai.dto.AiClassifyRequest;
import com.kbw.caplog.ai.dto.AiClassifyResponse;
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

    @PostMapping("/classify")
    public Mono<AiClassifyResponse> classify(@Valid @RequestBody AiClassifyRequest request) {
        return openAiClassificationService.classify(request.prompt());
    }
}
