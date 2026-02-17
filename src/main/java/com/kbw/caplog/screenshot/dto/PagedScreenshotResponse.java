package com.kbw.caplog.screenshot.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class PagedScreenshotResponse {

    private List<ScreenshotItemDto> items;
    private String nextCursor;
}
