package com.kbw.caplog.chat;

import com.kbw.caplog.chat.dto.*;
import com.kbw.caplog.user.User;
import com.kbw.caplog.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/share/chats")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;
    private final UserRepository userRepository;

    @GetMapping
    public ResponseEntity<List<ChatSummaryDto>> listChats(Authentication auth) {
        Long userNo = resolveUserNo(auth);
        if (userNo == null) return ResponseEntity.status(401).build();
        return ResponseEntity.ok(chatService.listRooms(userNo));
    }

    @PostMapping
    public ResponseEntity<ChatSummaryDto> createChat(Authentication auth, @RequestBody CreateChatRequest request) {
        Long userNo = resolveUserNo(auth);
        if (userNo == null) return ResponseEntity.status(401).build();
        try {
            return ResponseEntity.ok(chatService.createRoom(userNo, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/{chatId}/messages")
    public ResponseEntity<List<ChatMessageDto>> getMessages(Authentication auth, @PathVariable String chatId) {
        Long userNo = resolveUserNo(auth);
        if (userNo == null) return ResponseEntity.status(401).build();
        try {
            Long roomId = Long.parseLong(chatId);
            return ResponseEntity.ok(chatService.getMessages(roomId, userNo));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/{chatId}/messages")
    public ResponseEntity<ChatMessageDto> sendMessage(Authentication auth, @PathVariable String chatId, @RequestBody SendMessageRequest request) {
        Long userNo = resolveUserNo(auth);
        if (userNo == null) return ResponseEntity.status(401).build();
        try {
            Long roomId = Long.parseLong(chatId);
            return ResponseEntity.ok(chatService.sendMessage(roomId, userNo, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PatchMapping("/{chatId}/read")
    public ResponseEntity<Void> markRead(Authentication auth, @PathVariable String chatId) {
        Long userNo = resolveUserNo(auth);
        if (userNo == null) return ResponseEntity.status(401).build();
        try {
            Long roomId = Long.parseLong(chatId);
            chatService.markRead(roomId, userNo);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    private Long resolveUserNo(Authentication auth) {
        if (auth == null || auth.getName() == null || auth.getName().isBlank()) return null;
        return userRepository.findByEmail(auth.getName()).map(User::getUserNo).orElse(null);
    }
}
