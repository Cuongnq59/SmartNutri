package com.smartnutri.controller;

import com.smartnutri.dto.MealAnalysisRequest;
import com.smartnutri.dto.MealAnalysisResponse;
import com.smartnutri.dto.QuickAdjustRequest;
import com.smartnutri.service.GeminiVisionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/vision")
public class VisionController {

    private final GeminiVisionService visionService;

    public VisionController(GeminiVisionService visionService) {
        this.visionService = visionService;
    }

    @PostMapping("/analyze-meal")
    public ResponseEntity<MealAnalysisResponse> analyzeMeal(@RequestBody MealAnalysisRequest request) {
        MealAnalysisResponse response = visionService.analyzeMealImage(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/quick-adjust")
    public ResponseEntity<MealAnalysisResponse> quickAdjust(@RequestBody QuickAdjustRequest request) {
        MealAnalysisResponse response = visionService.recalculateQuickAdjust(request);
        return ResponseEntity.ok(response);
    }
}
