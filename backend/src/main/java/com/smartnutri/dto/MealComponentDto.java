package com.smartnutri.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MealComponentDto {
    private String name;
    private Double estimatedWeightG;
    private Double calories;
    private Double proteinG;
    private Double carbsG;
    private Double fatG;
}
