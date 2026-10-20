package com.smartnutri.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MealAnalysisRequest {
    private String base64Image;
    private String imageUrl;
    private String mimeType; // e.g. "image/jpeg"
}
