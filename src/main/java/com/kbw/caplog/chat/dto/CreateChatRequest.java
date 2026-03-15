package com.kbw.caplog.chat.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class CreateChatRequest {

    /** 참여자 userId 목록 (본인 제외, 서버에서 현재 사용자 추가) */
    private List<String> participantUserIds;
}
