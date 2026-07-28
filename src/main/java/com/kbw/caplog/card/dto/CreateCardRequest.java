package com.kbw.caplog.card.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
import java.util.Map;

/**
 * iOS/클라이언트에서 스크린샷 AI 분류 후 카드 생성 시 전송하는 요청 body
 */
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class CreateCardRequest {

    private String title;
    private String summary;
    /** 대분류: Info, Contents, Social, Log, Music/Art, Etc. */
    private String category;
    private String subcategory;
    private List<String> tags;
    private Map<String, String> fields;
    /**
     * 이전 앱과의 요청 호환용입니다. 개인정보 보호 정책에 따라 서버에서는 무시합니다.
     */
    private String thumbnailURL;
    private List<String> screenshotURLs;
}
