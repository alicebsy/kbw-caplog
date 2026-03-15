package com.kbw.caplog.user.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class AddFriendRequest {

    private String userId;   // 추가할 친구의 userId (iOS에서 "userId"로 전송)
    private String name;    // optional, 무시 가능
}
