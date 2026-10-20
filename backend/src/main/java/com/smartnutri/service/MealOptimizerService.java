package com.smartnutri.service;

import com.smartnutri.dto.MealOptimizeRequest;
import com.smartnutri.dto.MealOptimizeResponse;
import com.smartnutri.dto.OptimizedItemDto;
import com.smartnutri.model.IngredientRef;
import com.smartnutri.model.PantryItem;
import com.smartnutri.repository.IngredientRefRepository;
import com.smartnutri.repository.PantryItemRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class MealOptimizerService {

    private static final Logger log = LoggerFactory.getLogger(MealOptimizerService.class);

    private final IngredientRefRepository ingredientRefRepository;
    private final PantryItemRepository pantryItemRepository;

    public MealOptimizerService(IngredientRefRepository ingredientRefRepository,
                                PantryItemRepository pantryItemRepository) {
        this.ingredientRefRepository = ingredientRefRepository;
        this.pantryItemRepository = pantryItemRepository;
    }

    public static class CandidateItem {
        public Long id;
        public String name;
        public boolean isDiscrete;
        public String unit;
        public double costPerUnit; // VNĐ
        public double proteinPerUnit; // g
        public double caloriesPerUnit; // kcal
        public double maxPortion;
        public boolean fromPantry;

        public CandidateItem(Long id, String name, boolean isDiscrete, String unit,
                             double costPerUnit, double proteinPerUnit, double caloriesPerUnit,
                             double maxPortion, boolean fromPantry) {
            this.id = id;
            this.name = name;
            this.isDiscrete = isDiscrete;
            this.unit = unit;
            this.costPerUnit = costPerUnit;
            this.proteinPerUnit = proteinPerUnit;
            this.caloriesPerUnit = caloriesPerUnit;
            this.maxPortion = maxPortion;
            this.fromPantry = fromPantry;
        }
    }

    public MealOptimizeResponse optimizeMeal(MealOptimizeRequest request) {
        double targetProtein = request.getTargetProtein() != null ? request.getTargetProtein() : 45.0;
        double minCalories = request.getMinCalories() != null ? request.getMinCalories() : 450.0;
        double maxCalories = request.getMaxCalories() != null ? request.getMaxCalories() : 850.0;
        double maxBudget = request.getMaxBudget() != null ? request.getMaxBudget() : 50000.0;
        boolean usePantry = request.getUsePantryItems() == null || request.getUsePantryItems();

        List<CandidateItem> candidates = buildCandidatePool(request.getUserId(), usePantry);

        if (candidates.isEmpty()) {
            return MealOptimizeResponse.builder()
                    .isFeasible(false)
                    .totalCost(0.0)
                    .totalProtein(0.0)
                    .totalCalories(0.0)
                    .items(Collections.emptyList())
                    .shoppingAdvice("Chưa có dữ liệu thực phẩm trong hệ thống.")
                    .statusMessage("Thiếu danh mục thực phẩm.")
                    .build();
        }

        // Branch-and-Bound / MILP Solver
        OptimizationResult bestResult = solveMilp(candidates, targetProtein, minCalories, maxCalories, maxBudget);

        if (bestResult != null && bestResult.feasible) {
            return buildFeasibleResponse(bestResult, candidates);
        } else {
            // Edge Case: Infeasible within current budget -> find minimum budget required
            return handleInfeasibleCase(candidates, targetProtein, minCalories, maxCalories, maxBudget);
        }
    }

    private List<CandidateItem> buildCandidatePool(Long userId, boolean usePantry) {
        List<CandidateItem> list = new ArrayList<>();
        Set<String> pantryNames = new HashSet<>();

        // 1. Check virtual pantry items for this user (Cost = 0 VNĐ)
        if (usePantry && userId != null) {
            List<PantryItem> pantryItems = pantryItemRepository.findByUserIdAndStatus(userId, PantryItem.PantryStatus.ACTIVE);
            for (PantryItem p : pantryItems) {
                if (p.getQuantity() != null && p.getQuantity() > 0) {
                    double protein = 0;
                    double calories = 0;
                    boolean discrete = true;
                    String unit = p.getUnit();
                    double portion = p.getQuantity();

                    if (p.getIngredientRef() != null) {
                        IngredientRef ref = p.getIngredientRef();
                        discrete = Boolean.TRUE.equals(ref.getIsDiscrete());
                        if (discrete) {
                            double weightG = ref.getStandardWeightG() != null ? ref.getStandardWeightG() : 50.0;
                            protein = (ref.getProteinPer100g() * weightG) / 100.0;
                            calories = (ref.getCaloriesPer100g() * weightG) / 100.0;
                            portion = Math.min(p.getQuantity(), 3.0); // max 3 eggs / 3 pieces
                        } else {
                            // continuous per 100g
                            protein = ref.getProteinPer100g();
                            calories = ref.getCaloriesPer100g();
                            portion = Math.min(p.getQuantity() / 100.0, 3.0); // max 3 lạng
                            unit = "lạng (100g)";
                        }
                    } else {
                        protein = 10.0;
                        calories = 120.0;
                    }

                    pantryNames.add(p.getCustomName().toLowerCase());
                    list.add(new CandidateItem(p.getId(), p.getCustomName() + " (Từ tủ lạnh)",
                            discrete, unit, 0.0, protein, calories, portion, true));
                }
            }
        }

        // 2. Add local student ingredient catalog
        List<IngredientRef> catalog = ingredientRefRepository.findAll();
        for (IngredientRef ref : catalog) {
            boolean discrete = Boolean.TRUE.equals(ref.getIsDiscrete());
            double costPerUnit = ref.getAvgPriceVnd() != null ? ref.getAvgPriceVnd() : 10000.0;
            double proteinPerUnit = 0;
            double caloriesPerUnit = 0;
            String unit = ref.getStandardUnit() != null ? ref.getStandardUnit() : "lạng";

            if (discrete) {
                double weightG = ref.getStandardWeightG() != null ? ref.getStandardWeightG() : 50.0;
                proteinPerUnit = (ref.getProteinPer100g() * weightG) / 100.0;
                caloriesPerUnit = (ref.getCaloriesPer100g() * weightG) / 100.0;
            } else {
                // per 100g
                proteinPerUnit = ref.getProteinPer100g();
                caloriesPerUnit = ref.getCaloriesPer100g();
                unit = "lạng (100g)";
            }

            double maxPortion = ref.getMaxPortion() != null ? ref.getMaxPortion() : (discrete ? 3.0 : 3.0);
            list.add(new CandidateItem(ref.getId(), ref.getName(), discrete, unit,
                    costPerUnit, proteinPerUnit, caloriesPerUnit, maxPortion, false));
        }

        return list;
    }

    private static class OptimizationResult {
        public boolean feasible = false;
        public double totalCost = Double.MAX_VALUE;
        public double totalProtein = 0;
        public double totalCalories = 0;
        public Map<Integer, Double> solution = new HashMap<>();
    }

    private OptimizationResult solveMilp(List<CandidateItem> candidates,
                                         double targetProtein,
                                         double minCalories,
                                         double maxCalories,
                                         double maxBudget) {
        int n = candidates.size();
        OptimizationResult best = new OptimizationResult();

        // High efficiency heuristic branch-and-bound search
        // Sort items by protein-per-cost efficiency ratio
        List<Integer> indices = new ArrayList<>();
        for (int i = 0; i < n; i++) indices.add(i);
        indices.sort((a, b) -> {
            CandidateItem ca = candidates.get(a);
            CandidateItem cb = candidates.get(b);
            double effA = ca.costPerUnit <= 0 ? 9999.0 : ca.proteinPerUnit / ca.costPerUnit;
            double effB = cb.costPerUnit <= 0 ? 9999.0 : cb.proteinPerUnit / cb.costPerUnit;
            return Double.compare(effB, effA);
        });

        searchRecursive(candidates, indices, 0, new HashMap<>(), 0.0, 0.0, 0.0,
                targetProtein, minCalories, maxCalories, maxBudget, best, 0);

        return best;
    }

    private void searchRecursive(List<CandidateItem> candidates,
                                 List<Integer> sortedIndices,
                                 int depth,
                                 Map<Integer, Double> currentChoice,
                                 double currentCost,
                                 double currentProtein,
                                 double currentCalories,
                                 double targetProtein,
                                 double minCalories,
                                 double maxCalories,
                                 double maxBudget,
                                 OptimizationResult best,
                                 int countNonZero) {

        // Pruning checks
        if (currentCost >= best.totalCost) return;
        if (currentCost > maxBudget) return;
        if (currentCalories > maxCalories) return;

        // Check feasibility if we met protein & calories criteria
        if (currentProtein >= targetProtein && currentCalories >= minCalories && currentCalories <= maxCalories) {
            // Variety constraint check: no single item exceeds 60% of total protein
            boolean varietyOk = true;
            for (Map.Entry<Integer, Double> entry : currentChoice.entrySet()) {
                double itemProtein = candidates.get(entry.getKey()).proteinPerUnit * entry.getValue();
                if (itemProtein > 0.60 * currentProtein) {
                    varietyOk = false;
                    break;
                }
            }

            if (varietyOk && currentCost < best.totalCost) {
                best.feasible = true;
                best.totalCost = currentCost;
                best.totalProtein = currentProtein;
                best.totalCalories = currentCalories;
                best.solution = new HashMap<>(currentChoice);
            }
            return;
        }

        if (depth >= sortedIndices.size() || countNonZero >= 4) {
            return;
        }

        int itemIdx = sortedIndices.get(depth);
        CandidateItem item = candidates.get(itemIdx);

        // Try candidate item portions
        double step = item.isDiscrete ? 1.0 : 0.5; // continuous step 0.5 lạng (50g)
        double maxP = item.maxPortion;

        // Try from 0 up to maxPortion
        for (double p = 0; p <= maxP + 1e-4; p += step) {
            if (p > 0) {
                currentChoice.put(itemIdx, p);
                double nextCost = currentCost + p * item.costPerUnit;
                double nextProtein = currentProtein + p * item.proteinPerUnit;
                double nextCalories = currentCalories + p * item.caloriesPerUnit;

                searchRecursive(candidates, sortedIndices, depth + 1, currentChoice,
                        nextCost, nextProtein, nextCalories,
                        targetProtein, minCalories, maxCalories, maxBudget, best, countNonZero + 1);

                currentChoice.remove(itemIdx);
            } else {
                // p == 0: skip item
                searchRecursive(candidates, sortedIndices, depth + 1, currentChoice,
                        currentCost, currentProtein, currentCalories,
                        targetProtein, minCalories, maxCalories, maxBudget, best, countNonZero);
            }
        }
    }

    private MealOptimizeResponse buildFeasibleResponse(OptimizationResult result, List<CandidateItem> candidates) {
        List<OptimizedItemDto> items = new ArrayList<>();
        StringBuilder advice = new StringBuilder("Gợi ý mua sắm: ");

        List<String> textParts = new ArrayList<>();
        for (Map.Entry<Integer, Double> entry : result.solution.entrySet()) {
            if (entry.getValue() > 0) {
                CandidateItem item = candidates.get(entry.getKey());
                double portion = Math.round(entry.getValue() * 10.0) / 10.0;
                double cost = Math.round(portion * item.costPerUnit);
                double pro = Math.round(portion * item.proteinPerUnit * 10.0) / 10.0;
                double cal = Math.round(portion * item.caloriesPerUnit);

                items.add(OptimizedItemDto.builder()
                        .name(item.name)
                        .portion(portion)
                        .unit(item.unit)
                        .cost(cost)
                        .protein(pro)
                        .calories(cal)
                        .fromPantry(item.fromPantry)
                        .build());

                String portionStr = item.isDiscrete ? ((int) portion + " " + item.unit) : (portion + " " + item.unit);
                String costStr = item.fromPantry ? "0đ" : ((int) (cost / 1000) + "k");
                textParts.add(portionStr + " " + item.name.replace(" (Từ tủ lạnh)", "") + " (" + costStr + ")");
            }
        }

        advice.append(String.join(" + ", textParts));
        advice.append(" = ").append(String.format("%,d", (long) result.totalCost)).append(" VNĐ");
        advice.append(" ➔ Cung cấp ").append(Math.round(result.totalProtein)).append("g protein");
        advice.append(" & ").append(Math.round(result.totalCalories)).append(" kcal.");

        return MealOptimizeResponse.builder()
                .isFeasible(true)
                .totalCost(result.totalCost)
                .totalProtein(Math.round(result.totalProtein * 10.0) / 10.0)
                .totalCalories((double) Math.round(result.totalCalories))
                .items(items)
                .shoppingAdvice(advice.toString())
                .statusMessage("Tìm thấy thực đơn tối ưu chi phí thành công!")
                .shortfallProtein(0.0)
                .neededExtraBudget(0.0)
                .build();
    }

    private MealOptimizeResponse handleInfeasibleCase(List<CandidateItem> candidates,
                                                      double targetProtein,
                                                      double minCalories,
                                                      double maxCalories,
                                                      double maxBudget) {
        // Find minimum cost to achieve targetProtein regardless of budget limit
        OptimizationResult minCostResult = solveMilp(candidates, targetProtein, minCalories, maxCalories, 999999.0);

        if (minCostResult.feasible) {
            double extraNeeded = Math.max(0.0, minCostResult.totalCost - maxBudget);
            double extraRounded = Math.ceil(extraNeeded / 1000.0) * 1000.0;

            List<OptimizedItemDto> items = new ArrayList<>();
            for (Map.Entry<Integer, Double> entry : minCostResult.solution.entrySet()) {
                CandidateItem item = candidates.get(entry.getKey());
                double portion = Math.round(entry.getValue() * 10.0) / 10.0;
                items.add(OptimizedItemDto.builder()
                        .name(item.name)
                        .portion(portion)
                        .unit(item.unit)
                        .cost((double) Math.round(portion * item.costPerUnit))
                        .protein(Math.round(portion * item.proteinPerUnit * 10.0) / 10.0)
                        .calories((double) Math.round(portion * item.caloriesPerUnit))
                        .fromPantry(item.fromPantry)
                        .build());
            }

            return MealOptimizeResponse.builder()
                    .isFeasible(false)
                    .totalCost(minCostResult.totalCost)
                    .totalProtein(minCostResult.totalProtein)
                    .totalCalories(minCostResult.totalCalories)
                    .items(items)
                    .shoppingAdvice("Ngân sách hiện tại (" + String.format("%,d", (long) maxBudget) + "đ) chưa đủ để nạp đủ "
                            + (int) targetProtein + "g protein. Cần thêm tối thiểu "
                            + String.format("%,d", (long) extraRounded) + " VNĐ để có thực đơn đủ đạm.")
                    .statusMessage("Ngân sách chưa đủ. Đã tính toán ngân sách tối thiểu cần thiết.")
                    .shortfallProtein(0.0)
                    .neededExtraBudget(extraRounded)
                    .build();
        }

        return MealOptimizeResponse.builder()
                .isFeasible(false)
                .totalCost(0.0)
                .totalProtein(0.0)
                .totalCalories(0.0)
                .items(Collections.emptyList())
                .shoppingAdvice("Không thể thỏa mãn đồng thời mục tiêu đạm và calo với các ràng buộc hiện tại. Hãy nới lỏng mức calo hoặc giảm chỉ tiêu đạm.")
                .statusMessage("Không tìm thấy giải pháp thỏa mãn.")
                .shortfallProtein(targetProtein)
                .neededExtraBudget(15000.0)
                .build();
    }
}
