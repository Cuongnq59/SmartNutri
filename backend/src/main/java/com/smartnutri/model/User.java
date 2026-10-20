package com.smartnutri.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(unique = true)
    private String firebaseUid;

    private String fullName;

    private Double height; // cm
    private Double weight; // kg
    private Double targetWeight; // kg

    @Enumerated(EnumType.STRING)
    private GoalType goalType; // BULK, CUT, MAINTAIN

    private String activityLevel; // SEDENTARY, LIGHT, MODERATE, VERY_ACTIVE

    private Double dailyCalorieTarget;
    private Double dailyProteinTarget; // g
    private Double dailyCarbsTarget; // g
    private Double dailyFatTarget; // g

    private Double weeklyBudget; // VNĐ
    private Double rmr; // kcal
    private Double tdee; // kcal

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public enum GoalType {
        BULK, CUT, MAINTAIN
    }

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
