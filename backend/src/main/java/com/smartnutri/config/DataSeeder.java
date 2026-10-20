package com.smartnutri.config;

import com.smartnutri.model.*;
import com.smartnutri.repository.*;
import com.smartnutri.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Component
public class DataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final IngredientRefRepository ingredientRefRepository;
    private final UserRepository userRepository;
    private final PantryItemRepository pantryItemRepository;
    private final MealRepository mealRepository;
    private final BudgetLogRepository budgetLogRepository;
    private final UserService userService;

    public DataSeeder(IngredientRefRepository ingredientRefRepository,
                      UserRepository userRepository,
                      PantryItemRepository pantryItemRepository,
                      MealRepository mealRepository,
                      BudgetLogRepository budgetLogRepository,
                      UserService userService) {
        this.ingredientRefRepository = ingredientRefRepository;
        this.userRepository = userRepository;
        this.pantryItemRepository = pantryItemRepository;
        this.mealRepository = mealRepository;
        this.budgetLogRepository = budgetLogRepository;
        this.userService = userService;
    }

    @Override
    public void run(String... args) {
        seedIngredients();
        User defaultUser = seedDefaultUser();
        seedPantryAndMeals(defaultUser);
    }

    private void seedIngredients() {
        if (ingredientRefRepository.count() > 0) return;

        log.info("Seeding Vietnamese student food catalog (local_ingredients_ref)...");
        List<IngredientRef> list = List.of(
                IngredientRef.builder()
                        .name("Ức gà phi lê")
                        .aliases("uc ga,uc ga cp,thit luon ga,ga phi le,uc ga dong lanh")
                        .avgPriceVnd(6500.0) // 6.5k / lạng (65k/kg)
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(31.0)
                        .caloriesPer100g(165.0)
                        .carbsPer100g(0.0)
                        .fatPer100g(3.6)
                        .isDiscrete(false)
                        .maxPortion(3.0)
                        .defaultShelfLifeDays(3)
                        .category("MEAT")
                        .build(),

                IngredientRef.builder()
                        .name("Trứng gà công nghiệp")
                        .aliases("trung ga,trung ga cp,trung ba huan,trung ga do,qua trung")
                        .avgPriceVnd(2800.0) // 2.8k / quả
                        .standardUnit("quả")
                        .standardWeightG(50.0)
                        .proteinPer100g(13.0)
                        .caloriesPer100g(144.0)
                        .carbsPer100g(0.8)
                        .fatPer100g(9.5)
                        .isDiscrete(true)
                        .maxPortion(3.0)
                        .defaultShelfLifeDays(21)
                        .category("EGG")
                        .build(),

                IngredientRef.builder()
                        .name("Đậu phụ Mơ")
                        .aliases("dau phu,dau mo,dau hu,dau trang,dau bia,tofu")
                        .avgPriceVnd(4000.0) // 4k / bìa (100g)
                        .standardUnit("bìa")
                        .standardWeightG(100.0)
                        .proteinPer100g(10.0)
                        .caloriesPer100g(90.0)
                        .carbsPer100g(2.0)
                        .fatPer100g(4.5)
                        .isDiscrete(true)
                        .maxPortion(3.0)
                        .defaultShelfLifeDays(4)
                        .category("TOFU")
                        .build(),

                IngredientRef.builder()
                        .name("Thịt heo nạc vai")
                        .aliases("thit nac,thit heo nac,thit lon nac,thit vai,nac dam")
                        .avgPriceVnd(11000.0) // 11k / lạng
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(26.0)
                        .caloriesPer100g(180.0)
                        .carbsPer100g(0.0)
                        .fatPer100g(7.0)
                        .isDiscrete(false)
                        .maxPortion(2.5)
                        .defaultShelfLifeDays(3)
                        .category("MEAT")
                        .build(),

                IngredientRef.builder()
                        .name("Cá nục tươi")
                        .aliases("ca nuc,ca bien,ca nuc lam sach,ca nuc tuoi")
                        .avgPriceVnd(6000.0) // 6k / lạng (60k/kg)
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(21.0)
                        .caloriesPer100g(150.0)
                        .carbsPer100g(0.0)
                        .fatPer100g(6.5)
                        .isDiscrete(false)
                        .maxPortion(2.5)
                        .defaultShelfLifeDays(3)
                        .category("MEAT")
                        .build(),

                IngredientRef.builder()
                        .name("Gan heo")
                        .aliases("gan heo,gan lon,gan tuoi")
                        .avgPriceVnd(4000.0) // 4k / lạng (40k/kg)
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(21.3)
                        .caloriesPer100g(134.0)
                        .carbsPer100g(3.0)
                        .fatPer100g(3.5)
                        .isDiscrete(false)
                        .maxPortion(1.5)
                        .defaultShelfLifeDays(2)
                        .category("MEAT")
                        .build(),

                IngredientRef.builder()
                        .name("Gạo tẻ ST25")
                        .aliases("gao te,gao trang,com,gao st25,gao thom")
                        .avgPriceVnd(2200.0) // 2.2k / lạng gạo khô
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(7.5)
                        .caloriesPer100g(350.0)
                        .carbsPer100g(78.0)
                        .fatPer100g(0.8)
                        .isDiscrete(false)
                        .maxPortion(2.0)
                        .defaultShelfLifeDays(180)
                        .category("STARCH")
                        .build(),

                IngredientRef.builder()
                        .name("Rau muống")
                        .aliases("rau muong,rau xanh,rau muong lang,rau luoc")
                        .avgPriceVnd(2000.0) // 2k / lạng (10k/bó 500g)
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(3.0)
                        .caloriesPer100g(25.0)
                        .carbsPer100g(3.5)
                        .fatPer100g(0.2)
                        .isDiscrete(false)
                        .maxPortion(3.0)
                        .defaultShelfLifeDays(4)
                        .category("VEGETABLE")
                        .build(),

                IngredientRef.builder()
                        .name("Bắp cải trắng")
                        .aliases("bap cai,bap cai trang,cai bap")
                        .avgPriceVnd(1200.0) // 1.2k / lạng
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(1.5)
                        .caloriesPer100g(25.0)
                        .carbsPer100g(5.0)
                        .fatPer100g(0.1)
                        .isDiscrete(false)
                        .maxPortion(3.0)
                        .defaultShelfLifeDays(7)
                        .category("VEGETABLE")
                        .build(),

                IngredientRef.builder()
                        .name("Sữa tươi tiệt trùng 220ml")
                        .aliases("sua tuoi,vinamilk,sua th,sua khong duong,sua co duong")
                        .avgPriceVnd(8500.0)
                        .standardUnit("hộp")
                        .standardWeightG(220.0)
                        .proteinPer100g(3.2)
                        .caloriesPer100g(68.0)
                        .carbsPer100g(4.8)
                        .fatPer100g(3.8)
                        .isDiscrete(true)
                        .maxPortion(2.0)
                        .defaultShelfLifeDays(90)
                        .category("DAIRY")
                        .build(),

                IngredientRef.builder()
                        .name("Khoai lang luộc")
                        .aliases("khoai lang,khoai lang mat,khoai luoc")
                        .avgPriceVnd(2000.0) // 2k / lạng
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(2.0)
                        .caloriesPer100g(86.0)
                        .carbsPer100g(20.0)
                        .fatPer100g(0.1)
                        .isDiscrete(false)
                        .maxPortion(3.0)
                        .defaultShelfLifeDays(14)
                        .category("STARCH")
                        .build(),

                IngredientRef.builder()
                        .name("Chuối tiêu chín")
                        .aliases("chuoi,chuoi tieu,chuoi gia,qua chuoi")
                        .avgPriceVnd(3000.0)
                        .standardUnit("quả")
                        .standardWeightG(100.0)
                        .proteinPer100g(1.3)
                        .caloriesPer100g(90.0)
                        .carbsPer100g(23.0)
                        .fatPer100g(0.3)
                        .isDiscrete(true)
                        .maxPortion(2.0)
                        .defaultShelfLifeDays(5)
                        .category("OTHER")
                        .build(),

                IngredientRef.builder()
                        .name("Lạc nhân (Đậu phộng)")
                        .aliases("lac,lac nhan,dau phong,dau phong rang")
                        .avgPriceVnd(5000.0)
                        .standardUnit("lạng")
                        .standardWeightG(100.0)
                        .proteinPer100g(26.0)
                        .caloriesPer100g(567.0)
                        .carbsPer100g(16.0)
                        .fatPer100g(49.0)
                        .isDiscrete(false)
                        .maxPortion(0.5)
                        .defaultShelfLifeDays(90)
                        .category("OTHER")
                        .build()
        );

        ingredientRefRepository.saveAll(list);
        log.info("Seeded {} student food items successfully.", list.size());
    }

    private User seedDefaultUser() {
        return userRepository.findByEmail("sinhvien@smartnutri.vn").orElseGet(() -> {
            User user = User.builder()
                    .email("sinhvien@smartnutri.vn")
                    .fullName("Nguyễn Văn An")
                    .height(172.0)
                    .weight(64.0)
                    .targetWeight(68.0)
                    .goalType(User.GoalType.BULK)
                    .activityLevel("MODERATE")
                    .weeklyBudget(450000.0) // 450.000 VNĐ / tuần
                    .build();
            userService.calculateAndSetTargets(user);
            return userRepository.save(user);
        });
    }

    private void seedPantryAndMeals(User user) {
        if (pantryItemRepository.count() == 0) {
            log.info("Seeding Virtual Pantry items for demo user...");
            LocalDate today = LocalDate.now();

            IngredientRef eggRef = ingredientRefRepository.findByNameIgnoreCase("Trứng gà công nghiệp").orElse(null);
            IngredientRef chickenRef = ingredientRefRepository.findByNameIgnoreCase("Ức gà phi lê").orElse(null);
            IngredientRef tofuRef = ingredientRefRepository.findByNameIgnoreCase("Đậu phụ Mơ").orElse(null);

            List<PantryItem> pantryItems = List.of(
                    PantryItem.builder()
                            .userId(user.getId())
                            .ingredientRef(eggRef)
                            .customName("Trứng gà Ba Huân")
                            .rawName("TRUNG GA HOP 10Q")
                            .quantity(4.0)
                            .unit("piece")
                            .costPaid(11200.0)
                            .purchaseDate(today.minusDays(2))
                            .expiryDate(today.plusDays(19))
                            .status(PantryItem.PantryStatus.ACTIVE)
                            .build(),

                    PantryItem.builder()
                            .userId(user.getId())
                            .ingredientRef(chickenRef)
                            .customName("Ức gà phi lê CP")
                            .rawName("UC GA PHI LE 300G")
                            .quantity(250.0)
                            .unit("g")
                            .costPaid(19000.0)
                            .purchaseDate(today.minusDays(1))
                            .expiryDate(today.plusDays(2)) // Sắp hết hạn (badge vàng/đỏ)
                            .status(PantryItem.PantryStatus.ACTIVE)
                            .build(),

                    PantryItem.builder()
                            .userId(user.getId())
                            .ingredientRef(tofuRef)
                            .customName("Đậu phụ Mơ")
                            .rawName("DAU PHU BIA")
                            .quantity(2.0)
                            .unit("piece")
                            .costPaid(8000.0)
                            .purchaseDate(today)
                            .expiryDate(today.plusDays(3))
                            .status(PantryItem.PantryStatus.ACTIVE)
                            .build()
            );

            pantryItemRepository.saveAll(pantryItems);
        }

        if (mealRepository.count() == 0) {
            log.info("Seeding sample meals and budget logs...");
            Meal breakfast = Meal.builder()
                    .userId(user.getId())
                    .dishName("Bánh mì pate trứng ốp la + Sữa đậu nành")
                    .mealType(Meal.MealType.BREAKFAST)
                    .totalCalories(520.0)
                    .totalProtein(24.5)
                    .totalCarbs(58.0)
                    .totalFat(19.0)
                    .cost(25000.0)
                    .healthNote("Bữa sáng nạp đủ năng lượng và đạm, chuẩn bị tốt cho buổi học.")
                    .createdAt(LocalDateTime.now().minusHours(4))
                    .build();

            List<MealItem> items = List.of(
                    MealItem.builder().meal(breakfast).itemName("Bánh mì giòn").weightG(80.0).calories(220.0).protein(6.0).carbs(45.0).fat(1.5).build(),
                    MealItem.builder().meal(breakfast).itemName("2 trứng ốp la").weightG(100.0).calories(160.0).protein(13.0).carbs(1.0).fat(11.0).build(),
                    MealItem.builder().meal(breakfast).itemName("Pate gan & dưa leo").weightG(40.0).calories(80.0).protein(3.5).carbs(2.0).fat(6.0).build(),
                    MealItem.builder().meal(breakfast).itemName("Sữa đậu nành không đường").weightG(200.0).calories(60.0).protein(2.0).carbs(10.0).fat(0.5).build()
            );
            breakfast.setItems(new ArrayList<>(items));
            mealRepository.save(breakfast);

            // Budget log for breakfast
            budgetLogRepository.save(BudgetLog.builder()
                    .userId(user.getId())
                    .amount(25000.0)
                    .category("FOOD")
                    .note("Bữa sáng bánh mì trứng")
                    .createdAt(LocalDateTime.now().minusHours(4))
                    .build());

            // Add supermarket purchase from 2 days ago
            budgetLogRepository.save(BudgetLog.builder()
                    .userId(user.getId())
                    .amount(78000.0)
                    .category("FOOD")
                    .note("Đi siêu thị WinMart mua ức gà, trứng, đậu phụ")
                    .createdAt(LocalDateTime.now().minusDays(2))
                    .build());
        }
    }
}
