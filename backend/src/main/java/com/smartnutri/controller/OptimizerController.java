package com.smartnutri.controller;

import com.smartnutri.dto.MealOptimizeRequest;
import com.smartnutri.dto.MealOptimizeResponse;
import com.smartnutri.service.MealOptimizerService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/optimizer")
public class OptimizerController {

    private final MealOptimizerService mealOptimizerService;

    public OptimizerController(MealOptimizerService mealOptimizerService) {
        this.mealOptimizerService = mealOptimizerService;
    }

    @PostMapping("/target-meal")
    public ResponseEntity<MealOptimizeResponse> optimizeTargetMeal(@RequestBody MealOptimizeRequest request) {
        MealOptimizeResponse response = mealOptimizerService.optimizeMeal(request);
        return ResponseEntity.ok(response);
    }
}
