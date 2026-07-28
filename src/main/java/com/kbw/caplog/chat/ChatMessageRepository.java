package com.kbw.caplog.chat;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    List<ChatMessage> findByChatRoomIdOrderByCreatedAtAsc(Long chatRoomId);

    Optional<ChatMessage> findTopByChatRoomIdOrderByCreatedAtDesc(Long chatRoomId);

    long countByChatRoomIdAndSenderUserNoNot(Long chatRoomId, Long senderUserNo);

    long countByChatRoomIdAndSenderUserNoNotAndCreatedAtAfter(
            Long chatRoomId,
            Long senderUserNo,
            Instant createdAt
    );

    void deleteByChatRoomId(Long chatRoomId);
}
