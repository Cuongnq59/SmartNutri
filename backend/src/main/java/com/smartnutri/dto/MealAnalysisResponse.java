package com.smartnutri.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MealAnalysisResponse {
    private String dishName;
    private Double confidenceScore;
    private Double estimatedWeightG;
    private NutritionSummaryDto nutritionSummary;
    private List<MealComponentDto> components;
    private String healthNote;
}
