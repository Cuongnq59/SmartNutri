package com.smartnutri.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MealOptimizeResponse {
    private Boolean isFeasible;
    private Double totalCost;
    private Double totalProtein;
    private Double totalCalories;
    private List<OptimizedItemDto> items;
    private String shoppingAdvice;
    private String statusMessage;
    private Double shortfallProtein;
    private Double neededExtraBudget;
}
