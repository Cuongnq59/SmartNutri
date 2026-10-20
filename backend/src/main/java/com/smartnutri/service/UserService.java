package com.smartnutri.service;

import com.smartnutri.model.User;
import com.smartnutri.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User getUserProfile(Long id) {
        return userRepository.findById(id).orElseGet(() -> {
            User defaultUser = User.builder()
                    .email("sinhvien@smartnutri.vn")
                    .fullName("Nguyễn Văn An")
                    .height(172.0)
                    .weight(64.0)
                    .targetWeight(68.0)
                    .goalType(User.GoalType.BULK)
                    .activityLevel("MODERATE")
                    .weeklyBudget(450000.0)
                    .build();
            calculateAndSetTargets(defaultUser);
            return userRepository.save(defaultUser);
        });
    }

    @Transactional
    public User updateProfile(Long id, User updateData) {
        User user = getUserProfile(id);
        if (updateData.getFullName() != null) user.setFullName(updateData.getFullName());
        if (updateData.getHeight() != null) user.setHeight(updateData.getHeight());
        if (updateData.getWeight() != null) user.setWeight(updateData.getWeight());
        if (updateData.getTargetWeight() != null) user.setTargetWeight(updateData.getTargetWeight());
        if (updateData.getGoalType() != null) user.setGoalType(updateData.getGoalType());
        if (updateData.getActivityLevel() != null) user.setActivityLevel(updateData.getActivityLevel());
        if (updateData.getWeeklyBudget() != null) user.setWeeklyBudget(updateData.getWeeklyBudget());

        calculateAndSetTargets(user);
        return userRepository.save(user);
    }

    public void calculateAndSetTargets(User user) {
        double weight = user.getWeight() != null ? user.getWeight() : 65.0;
        double height = user.getHeight() != null ? user.getHeight() : 170.0;
        int age = 21; // student average

        // Mifflin-St Jeor formula for RMR (Male default, or general)
        double rmr = 10 * weight + 6.25 * height - 5 * age + 5;
        user.setRmr(Math.round(rmr * 10.0) / 10.0);

        // Activity factor
        double activityFactor = 1.375; // LIGHT by default
        String level = user.getActivityLevel() != null ? user.getActivityLevel().toUpperCase() : "MODERATE";
        if (level.contains("SEDENTARY")) activityFactor = 1.2;
        else if (level.contains("LIGHT")) activityFactor = 1.375;
        else if (level.contains("MODERATE")) activityFactor = 1.55;
        else if (level.contains("VERY")) activityFactor = 1.725;

        double tdee = rmr * activityFactor;
        user.setTdee(Math.round(tdee * 10.0) / 10.0);

        // Daily targets based on goal roadmap (Lean Bulk / Cut / Maintain)
        double targetCalories = tdee;
        double proteinMultiplier = 1.8;

        User.GoalType goal = user.getGoalType() != null ? user.getGoalType() : User.GoalType.BULK;
        switch (goal) {
            case BULK -> {
                targetCalories = tdee + 350.0;
                proteinMultiplier = 2.0; // 2.0g protein / kg
            }
            case CUT -> {
                targetCalories = Math.max(1400.0, tdee - 450.0);
                proteinMultiplier = 2.2; // 2.2g protein / kg để giữ cơ
            }
            case MAINTAIN -> {
                targetCalories = tdee;
                proteinMultiplier = 1.6;
            }
        }

        double proteinG = Math.round(weight * proteinMultiplier);
        double fatG = Math.round((targetCalories * 0.25) / 9.0); // 25% calo từ fat
        double remainingCalories = targetCalories - (proteinG * 4.0 + fatG * 9.0);
        double carbsG = Math.round(Math.max(50.0, remainingCalories / 4.0));

        user.setDailyCalorieTarget((double) Math.round(targetCalories));
        user.setDailyProteinTarget(proteinG);
        user.setDailyCarbsTarget(carbsG);
        user.setDailyFatTarget(fatG);
    }
}
