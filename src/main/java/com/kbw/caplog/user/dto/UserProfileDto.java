package com.kbw.caplog.user.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.kbw.caplog.user.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileDto {

    /** DB PK (스크린샷 업로드 등에서 사용) */
    private Long userNo;
    private String userId;
    private String nickname;
    private String email;
    private String gender;
    private LocalDate birthday;

    @JsonProperty("avatar_url")
    private String avatarUrl;

    public static UserProfileDto from(User user) {
        return UserProfileDto.builder()
                .userNo(user.getUserNo())
                .userId(user.getUserId())
                .nickname(user.getName())
                .email(user.getEmail())
                .gender(user.getGender())
                .birthday(user.getBirthday())
                .avatarUrl(null)
                .build();
    }
}
