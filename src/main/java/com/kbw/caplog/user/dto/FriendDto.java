package com.kbw.caplog.user.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.kbw.caplog.user.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FriendDto {

    private String id;       // friend's userId (iOS expects "id")
    private String name;

    @JsonProperty("avatar_url")
    private String avatarUrl;

    public static FriendDto from(User user) {
        return FriendDto.builder()
                .id(user.getUserId())
                .name(user.getName() != null ? user.getName() : user.getUserId())
                .avatarUrl(null)
                .build();
    }
}
