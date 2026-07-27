package com.kbw.caplog.ai.dto;

import java.util.List;

public record VisionLabelsResponse(
        List<VisionLabelResponse> labels
) {
}
