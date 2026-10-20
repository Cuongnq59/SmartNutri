package com.smartnutri.dto;

import com.smartnutri.model.Meal;
import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardStatsResponse {
    private Long userId;
    private String userName;
    private String goalType;
    private Double todayCaloriesConsumed;
    private Double todayCaloriesTarget;
    private Double todayProteinConsumed;
    private Double todayProteinTarget;
    private Double todayCarbsConsumed;
    private Double todayCarbsTarget;
    private Double todayFatConsumed;
    private Double todayFatTarget;

    // Budget Watchdog
    private Double weeklyBudget;
    private Double weeklySpent;
    private Double weeklyRemaining;
    private Double dailyRemainingBudget;
    private String burnRateStatus; // NORMAL, WARNING, DANGER
    private String burnRateMessage;

    // Cost Per Gram of Protein (CPGP)
    private Double cpgpIndexVnd; // VNĐ / gram protein
    private String cpgpEvaluation; // "Tiết kiệm xuất sắc", "Hợp lý", "Khá tốn kém"

    private Integer activePantryCount;
    private Integer expiringPantryCount;
    private List<Meal> recentMeals;
}
