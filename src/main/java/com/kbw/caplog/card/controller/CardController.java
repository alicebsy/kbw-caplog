package com.kbw.caplog.card.controller;

import com.kbw.caplog.card.dto.CardDto;
import com.kbw.caplog.card.dto.CreateCardRequest;
import com.kbw.caplog.card.service.CardService;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 카드 API (프론트엔드 Home/Folder/Search 연동)
 * - GET /api/cards: 내 카드 목록 (Screenshot 기반)
 * - POST /api/cards: 카드 생성 (스크린샷 AI 분류 결과 저장)
 */
@RestController
@RequestMapping("/api/cards")
@RequiredArgsConstructor
public class CardController {

    private static final Logger log = LoggerFactory.getLogger(CardController.class);
    private final CardService cardService;
    private final UserRepository userRepository;

    /**
     * 내 카드 목록 조회 (JWT 필요)
     * - Screenshot(추천 도메인) 데이터를 Card 형식으로 변환해 반환
     */
    @GetMapping
    public ResponseEntity<List<CardDto>> getMyCards(
            Authentication auth,
            @RequestParam(defaultValue = "20") int limit
    ) {
        String email = auth != null ? auth.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(401).build();
        }
        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).build();
        }
        return ResponseEntity.ok(cardService.findCardsByUserNo(user.getUserNo(), limit));
    }

    /**
     * 카드 생성 (JWT 필요) - iOS 스크린샷 AI 분류 후 호출
     * - body: CreateCardRequest (title, summary, category, subcategory, tags, fields, thumbnailURL, screenshotURLs)
     * - OCR/GPT 결과를 screenshot 테이블에 저장
     */
    @PostMapping
    public ResponseEntity<CardDto> createCard(Authentication auth, @RequestBody CreateCardRequest body) {
        String email = auth != null ? auth.getName() : null;
        if (email == null || email.isBlank()) {
            return ResponseEntity.status(401).build();
        }
        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).build();
        }
        CardDto created = cardService.createCard(user.getUserNo(), body);
        log.info("카드 저장 완료 (userNo={}, title={})", user.getUserNo(), created.getTitle());
        return ResponseEntity.ok(created);
    }
}
