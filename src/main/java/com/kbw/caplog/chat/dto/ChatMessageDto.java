package com.kbw.caplog.chat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatMessageDto {

    private String id;
    private String chatId;
    private String senderId;
    private String senderName;
    private String text;
    private Instant createdAt;
}
