package com.smartnutri.controller;

import com.smartnutri.model.Meal;
import com.smartnutri.service.MealService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/meals")
public class MealController {

    private final MealService mealService;

    public MealController(MealService mealService) {
        this.mealService = mealService;
    }

    @GetMapping
    public ResponseEntity<List<Meal>> getMeals(@RequestParam(defaultValue = "1") Long userId) {
        return ResponseEntity.ok(mealService.getUserMeals(userId));
    }

    @PostMapping
    public ResponseEntity<Meal> logMeal(@RequestParam(defaultValue = "1") Long userId,
                                        @RequestParam(defaultValue = "false") boolean deductFromPantry,
                                        @RequestBody Meal meal) {
        meal.setUserId(userId);
        return ResponseEntity.ok(mealService.logMeal(meal, deductFromPantry));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteMeal(@PathVariable Long id) {
        mealService.deleteMeal(id);
        return ResponseEntity.ok(Map.of("message", "Đã xóa bữa ăn"));
    }
}
