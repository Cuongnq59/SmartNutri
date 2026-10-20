package com.smartnutri.service;

import com.smartnutri.dto.DashboardStatsResponse;
import com.smartnutri.model.*;
import com.smartnutri.repository.*;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
public class DashboardService {

    private final UserRepository userRepository;
    private final MealRepository mealRepository;
    private final BudgetLogRepository budgetLogRepository;
    private final PantryService pantryService;

    public DashboardService(UserRepository userRepository,
                            MealRepository mealRepository,
                            BudgetLogRepository budgetLogRepository,
                            PantryService pantryService) {
        this.userRepository = userRepository;
        this.mealRepository = mealRepository;
        this.budgetLogRepository = budgetLogRepository;
        this.pantryService = pantryService;
    }

    public DashboardStatsResponse getDashboardStats(Long userId) {
        User user = userRepository.findById(userId).orElseGet(() -> {
            // Default student profile if not found
            return User.builder()
                    .id(userId)
                    .fullName("Sinh viên SmartNutri")
                    .goalType(User.GoalType.BULK)
                    .dailyCalorieTarget(2200.0)
                    .dailyProteinTarget(120.0)
                    .dailyCarbsTarget(280.0)
                    .dailyFatTarget(65.0)
                    .weeklyBudget(450000.0) // 450.000 VNĐ / tuần
                    .build();
        });

        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.atTime(LocalTime.MAX);

        // Today's meals
        List<Meal> todayMeals = mealRepository.findByUserIdAndCreatedAtBetweenOrderByCreatedAtDesc(userId, startOfDay, endOfDay);

        double todayCalories = 0;
        double todayProtein = 0;
        double todayCarbs = 0;
        double todayFat = 0;

        for (Meal m : todayMeals) {
            todayCalories += (m.getTotalCalories() != null ? m.getTotalCalories() : 0);
            todayProtein += (m.getTotalProtein() != null ? m.getTotalProtein() : 0);
            todayCarbs += (m.getTotalCarbs() != null ? m.getTotalCarbs() : 0);
            todayFat += (m.getTotalFat() != null ? m.getTotalFat() : 0);
        }

        // Weekly Budget Watchdog (Start of week: Monday)
        LocalDate startOfWeek = today.with(DayOfWeek.MONDAY);
        LocalDateTime weekStartTime = startOfWeek.atStartOfDay();
        List<BudgetLog> weekLogs = budgetLogRepository.findByUserIdAndCreatedAtBetween(userId, weekStartTime, endOfDay);

        double weeklySpent = weekLogs.stream()
                .mapToDouble(b -> b.getAmount() != null ? b.getAmount() : 0)
                .sum();

        double weeklyBudget = user.getWeeklyBudget() != null ? user.getWeeklyBudget() : 450000.0;
        double weeklyRemaining = Math.max(0, weeklyBudget - weeklySpent);

        // Days passed in week (1 for Monday, up to 7 for Sunday)
        int dayOfWeekValue = today.getDayOfWeek().getValue();
        int remainingDays = Math.max(1, 8 - dayOfWeekValue);
        double dailyRemainingBudget = Math.round(weeklyRemaining / remainingDays);

        // Burn Rate Warning Logic (HD.txt Part 2.2)
        double expectedSpentPace = (weeklyBudget / 7.0) * dayOfWeekValue;
        String burnRateStatus = "NORMAL";
        String burnRateMessage = "Tiến độ chi tiêu ổn định (" + String.format("%,d", (long) dailyRemainingBudget) + "đ/ngày còn lại).";

        if (weeklySpent > weeklyBudget) {
            burnRateStatus = "CRITICAL";
            burnRateMessage = "Đã vượt ngân sách tuần! Hãy bật 'Chế độ Tiết kiệm Mục tiêu'.";
        } else if (weeklySpent > expectedSpentPace * 1.25) {
            burnRateStatus = "WARNING";
            burnRateMessage = "Cảnh báo tốc độ chi tiêu nhanh hơn dự kiến! Bạn đã tiêu "
                    + String.format("%,d", (long) weeklySpent) + "đ / " + String.format("%,d", (long) weeklyBudget) + "đ.";
        }

        // Cost Per Gram of Protein (CPGP) - HD.txt Part 4.2
        List<Meal> weekMeals = mealRepository.findByUserIdAndCreatedAtBetweenOrderByCreatedAtDesc(userId, weekStartTime, endOfDay);
        double totalWeekProtein = weekMeals.stream()
                .mapToDouble(m -> m.getTotalProtein() != null ? m.getTotalProtein() : 0)
                .sum();

        double cpgpIndex = 0.0;
        String cpgpEvaluation = "Chưa đủ dữ liệu tuần";
        if (totalWeekProtein > 0 && weeklySpent > 0) {
            cpgpIndex = Math.round((weeklySpent / totalWeekProtein) * 10.0) / 10.0;
            if (cpgpIndex <= 450.0) {
                cpgpEvaluation = "Tiết kiệm xuất sắc (Dưới 450đ/g đạm)";
            } else if (cpgpIndex <= 700.0) {
                cpgpEvaluation = "Mức độ hợp lý (450đ - 700đ/g đạm)";
            } else {
                cpgpEvaluation = "Khá tốn kém (> 700đ/g đạm) - Nên tăng tỷ trọng ức gà/trứng/đậu";
            }
        }

        // Virtual Pantry stats
        List<PantryItem> activePantry = pantryService.getActivePantryItems(userId);
        List<PantryItem> expiringPantry = pantryService.getExpiringSoonItems(userId);

        // Recent meals (last 5)
        List<Meal> allRecent = mealRepository.findByUserIdOrderByCreatedAtDesc(userId);
        List<Meal> recent = allRecent.size() > 5 ? allRecent.subList(0, 5) : allRecent;

        return DashboardStatsResponse.builder()
                .userId(userId)
                .userName(user.getFullName())
                .goalType(user.getGoalType() != null ? user.getGoalType().name() : "BULK")
                .todayCaloriesConsumed(Math.round(todayCalories * 10.0) / 10.0)
                .todayCaloriesTarget(user.getDailyCalorieTarget() != null ? user.getDailyCalorieTarget() : 2200.0)
                .todayProteinConsumed(Math.round(todayProtein * 10.0) / 10.0)
                .todayProteinTarget(user.getDailyProteinTarget() != null ? user.getDailyProteinTarget() : 120.0)
                .todayCarbsConsumed(Math.round(todayCarbs * 10.0) / 10.0)
                .todayCarbsTarget(user.getDailyCarbsTarget() != null ? user.getDailyCarbsTarget() : 280.0)
                .todayFatConsumed(Math.round(todayFat * 10.0) / 10.0)
                .todayFatTarget(user.getDailyFatTarget() != null ? user.getDailyFatTarget() : 65.0)
                .weeklyBudget(weeklyBudget)
                .weeklySpent(weeklySpent)
                .weeklyRemaining(weeklyRemaining)
                .dailyRemainingBudget(dailyRemainingBudget)
                .burnRateStatus(burnRateStatus)
                .burnRateMessage(burnRateMessage)
                .cpgpIndexVnd(cpgpIndex)
                .cpgpEvaluation(cpgpEvaluation)
                .activePantryCount(activePantry.size())
                .expiringPantryCount(expiringPantry.size())
                .recentMeals(recent)
                .build();
    }
}
