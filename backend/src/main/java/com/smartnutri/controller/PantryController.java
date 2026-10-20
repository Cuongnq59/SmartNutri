package com.smartnutri.controller;

import com.smartnutri.dto.SmartLeftoverRecipeDto;
import com.smartnutri.model.PantryItem;
import com.smartnutri.service.PantryService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/pantry")
public class PantryController {

    private final PantryService pantryService;

    public PantryController(PantryService pantryService) {
        this.pantryService = pantryService;
    }

    @GetMapping
    public ResponseEntity<List<PantryItem>> getPantry(@RequestParam(defaultValue = "1") Long userId) {
        return ResponseEntity.ok(pantryService.getActivePantryItems(userId));
    }

    @GetMapping("/expiring-soon")
    public ResponseEntity<List<PantryItem>> getExpiringSoon(@RequestParam(defaultValue = "1") Long userId) {
        return ResponseEntity.ok(pantryService.getExpiringSoonItems(userId));
    }

    @PostMapping
    public ResponseEntity<PantryItem> addPantryItem(@RequestParam(defaultValue = "1") Long userId,
                                                    @RequestBody PantryItem item) {
        return ResponseEntity.ok(pantryService.addPantryItem(userId, item));
    }

    @PutMapping("/{id}")
    public ResponseEntity<PantryItem> updatePantryItem(@PathVariable Long id,
                                                       @RequestBody PantryItem item) {
        return ResponseEntity.ok(pantryService.updatePantryItem(id, item));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePantryItem(@PathVariable Long id) {
        pantryService.deletePantryItem(id);
        return ResponseEntity.ok(Map.of("message", "Đã xóa nguyên liệu khỏi tủ lạnh"));
    }

    @PostMapping("/consume/{id}")
    public ResponseEntity<PantryItem> consumePantryItem(@PathVariable Long id,
                                                        @RequestParam(required = false) Double quantity) {
        return ResponseEntity.ok(pantryService.consumePantryItem(id, quantity));
    }

    @GetMapping("/smart-leftovers")
    public ResponseEntity<List<SmartLeftoverRecipeDto>> getSmartLeftovers(@RequestParam(defaultValue = "1") Long userId) {
        return ResponseEntity.ok(pantryService.getSmartLeftoversRecipes(userId));
    }
}
