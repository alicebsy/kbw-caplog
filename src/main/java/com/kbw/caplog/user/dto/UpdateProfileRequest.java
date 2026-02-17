package com.kbw.caplog.user.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Getter
@NoArgsConstructor
public class UpdateProfileRequest {

    private String nickname;
    private String gender;
    private LocalDate birthday;

    @JsonProperty("avatar_url")
    private String avatarUrl;
}
