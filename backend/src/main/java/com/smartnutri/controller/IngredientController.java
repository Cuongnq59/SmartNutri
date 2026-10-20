package com.smartnutri.controller;

import com.smartnutri.model.IngredientRef;
import com.smartnutri.repository.IngredientRefRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ingredients")
public class IngredientController {

    private final IngredientRefRepository ingredientRefRepository;

    public IngredientController(IngredientRefRepository ingredientRefRepository) {
        this.ingredientRefRepository = ingredientRefRepository;
    }

    @GetMapping
    public ResponseEntity<List<IngredientRef>> getAllIngredients() {
        return ResponseEntity.ok(ingredientRefRepository.findAll());
    }
}
