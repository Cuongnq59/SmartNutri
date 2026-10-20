package com.smartnutri.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NutritionSummaryDto {
    private Double calories;
    private Double proteinG;
    private Double carbsG;
    private Double fatG;
}
