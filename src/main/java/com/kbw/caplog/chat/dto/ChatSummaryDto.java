package com.kbw.caplog.chat.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatSummaryDto {

    private String id;
    private String title;
    private String lastMessage;
    private Instant updatedAt;
    private int unreadCount;
    private List<String> participantIds;

    @JsonProperty("avatar_url")
    private String avatarUrl;
}
