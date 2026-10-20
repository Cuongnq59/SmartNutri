package com.smartnutri.service;

import com.smartnutri.model.*;
import com.smartnutri.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class MealService {

    private final MealRepository mealRepository;
    private final PantryItemRepository pantryItemRepository;
    private final BudgetLogRepository budgetLogRepository;

    public MealService(MealRepository mealRepository,
                       PantryItemRepository pantryItemRepository,
                       BudgetLogRepository budgetLogRepository) {
        this.mealRepository = mealRepository;
        this.pantryItemRepository = pantryItemRepository;
        this.budgetLogRepository = budgetLogRepository;
    }

    public List<Meal> getUserMeals(Long userId) {
        return mealRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional
    public Meal logMeal(Meal meal, boolean deductFromPantry) {
        if (meal.getItems() != null) {
            for (MealItem item : meal.getItems()) {
                item.setMeal(meal);
            }
        }
        Meal saved = mealRepository.save(meal);

        // Deduct from virtual pantry if requested
        if (deductFromPantry && saved.getItems() != null) {
            List<PantryItem> activePantry = pantryItemRepository.findByUserIdAndStatus(
                    saved.getUserId(), PantryItem.PantryStatus.ACTIVE);

            for (MealItem item : saved.getItems()) {
                if (item.getItemName() == null || item.getItemName().isBlank()) continue;
                String itemNameLower = item.getItemName().toLowerCase();
                for (PantryItem p : activePantry) {
                    if (itemNameLower.contains(p.getCustomName().toLowerCase())
                            || p.getCustomName().toLowerCase().contains(itemNameLower)) {
                        // Deduct portion
                        double deductQty = (item.getWeightG() != null && item.getWeightG() > 0) ? item.getWeightG() : 1.0;
                        if ("g".equalsIgnoreCase(p.getUnit()) || "gam".equalsIgnoreCase(p.getUnit())) {
                            if (p.getQuantity() <= deductQty) {
                                p.setQuantity(0.0);
                                p.setStatus(PantryItem.PantryStatus.CONSUMED);
                            } else {
                                p.setQuantity(p.getQuantity() - deductQty);
                            }
                        } else {
                            // discrete (eggs / pieces)
                            if (p.getQuantity() <= 1.0) {
                                p.setQuantity(0.0);
                                p.setStatus(PantryItem.PantryStatus.CONSUMED);
                            } else {
                                p.setQuantity(p.getQuantity() - 1.0);
                            }
                        }
                        pantryItemRepository.save(p);
                        break;
                    }
                }
            }
        }

        // If meal had outside cost, add to budget log
        if (saved.getCost() != null && saved.getCost() > 0) {
            budgetLogRepository.save(BudgetLog.builder()
                    .userId(saved.getUserId())
                    .amount(saved.getCost())
                    .category("FOOD")
                    .note("Bữa ăn: " + saved.getDishName())
                    .build());
        }

        return saved;
    }

    @Transactional
    public void deleteMeal(Long mealId) {
        mealRepository.deleteById(mealId);
    }
}
