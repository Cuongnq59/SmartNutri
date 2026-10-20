package com.smartnutri.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MealOptimizeRequest {
    private Long userId;
    private Double targetProtein; // e.g., 50.0 g
    private Double minCalories; // e.g., 500.0 kcal
    private Double maxCalories; // e.g., 850.0 kcal
    private Double maxBudget; // e.g., 40000.0 VNĐ
    @Builder.Default
    private Boolean usePantryItems = true;
}
