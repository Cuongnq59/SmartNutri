package com.smartnutri.service;

import com.smartnutri.dto.ReceiptConfirmRequest;
import com.smartnutri.dto.ReceiptItemDto;
import com.smartnutri.dto.SmartLeftoverRecipeDto;
import com.smartnutri.model.*;
import com.smartnutri.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.*;

@Service
public class PantryService {

    private final PantryItemRepository pantryItemRepository;
    private final ReceiptLogRepository receiptLogRepository;
    private final BudgetLogRepository budgetLogRepository;
    private final IngredientRefRepository ingredientRefRepository;

    public PantryService(PantryItemRepository pantryItemRepository,
                         ReceiptLogRepository receiptLogRepository,
                         BudgetLogRepository budgetLogRepository,
                         IngredientRefRepository ingredientRefRepository) {
        this.pantryItemRepository = pantryItemRepository;
        this.receiptLogRepository = receiptLogRepository;
        this.budgetLogRepository = budgetLogRepository;
        this.ingredientRefRepository = ingredientRefRepository;
    }

    public List<PantryItem> getActivePantryItems(Long userId) {
        return pantryItemRepository.findByUserIdAndStatus(userId, PantryItem.PantryStatus.ACTIVE);
    }

    public List<PantryItem> getExpiringSoonItems(Long userId) {
        LocalDate threshold = LocalDate.now().plusDays(2);
        return getActivePantryItems(userId).stream()
                .filter(item -> item.getExpiryDate() != null && !item.getExpiryDate().isAfter(threshold))
                .toList();
    }

    @Transactional
    public PantryItem addPantryItem(Long userId, PantryItem item) {
        item.setUserId(userId);
        if (item.getPurchaseDate() == null) item.setPurchaseDate(LocalDate.now());
        if (item.getStatus() == null) item.setStatus(PantryItem.PantryStatus.ACTIVE);
        return pantryItemRepository.save(item);
    }

    @Transactional
    public PantryItem updatePantryItem(Long id, PantryItem updated) {
        return pantryItemRepository.findById(id).map(existing -> {
            existing.setCustomName(updated.getCustomName());
            existing.setQuantity(updated.getQuantity());
            existing.setUnit(updated.getUnit());
            existing.setCostPaid(updated.getCostPaid());
            existing.setExpiryDate(updated.getExpiryDate());
            existing.setStatus(updated.getStatus());
            return pantryItemRepository.save(existing);
        }).orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nguyên liệu id: " + id));
    }

    @Transactional
    public void deletePantryItem(Long id) {
        pantryItemRepository.deleteById(id);
    }

    @Transactional
    public PantryItem consumePantryItem(Long id, Double quantityConsumed) {
        PantryItem item = pantryItemRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy nguyên liệu"));

        if (quantityConsumed == null || quantityConsumed >= item.getQuantity()) {
            item.setQuantity(0.0);
            item.setStatus(PantryItem.PantryStatus.CONSUMED);
        } else {
            item.setQuantity(item.getQuantity() - quantityConsumed);
        }
        return pantryItemRepository.save(item);
    }

    @Transactional
    public void confirmReceiptToPantry(ReceiptConfirmRequest request) {
        Long userId = request.getUserId() != null ? request.getUserId() : 1L;
        LocalDate purchaseDate = request.getPurchaseDate() != null ?
                LocalDate.parse(request.getPurchaseDate()) : LocalDate.now();

        double totalFood = 0;
        List<PantryItem> newItems = new ArrayList<>();

        if (request.getItems() != null) {
            for (ReceiptItemDto dto : request.getItems()) {
                if (Boolean.TRUE.equals(dto.getSelected())) {
                    if ("FOOD".equalsIgnoreCase(dto.getCategory())) {
                        totalFood += (dto.getTotalPrice() != null ? dto.getTotalPrice() : 0);

                        IngredientRef ref = null;
                        if (dto.getMatchedRefId() != null) {
                            ref = ingredientRefRepository.findById(dto.getMatchedRefId()).orElse(null);
                        }

                        LocalDate expiry = dto.getExpiryDate() != null ?
                                LocalDate.parse(dto.getExpiryDate()) : purchaseDate.plusDays(7);

                        PantryItem pantry = PantryItem.builder()
                                .userId(userId)
                                .ingredientRef(ref)
                                .customName(dto.getCleanName())
                                .rawName(dto.getRawName())
                                .quantity(dto.getQuantity() != null ? dto.getQuantity() : 1.0)
                                .unit(dto.getUnit() != null ? dto.getUnit() : "pack")
                                .costPaid(dto.getTotalPrice() != null ? dto.getTotalPrice() : 0.0)
                                .purchaseDate(purchaseDate)
                                .expiryDate(expiry)
                                .status(PantryItem.PantryStatus.ACTIVE)
                                .build();

                        newItems.add(pantry);
                    }
                }
            }
            pantryItemRepository.saveAll(newItems);
        }

        // 1. Save Receipt Log
        receiptLogRepository.save(ReceiptLog.builder()
                .userId(userId)
                .merchantName(request.getMerchantName() != null ? request.getMerchantName() : "Siêu thị")
                .totalAmount(request.getTotalAmount() != null ? request.getTotalAmount() : totalFood)
                .foodAmount(totalFood)
                .receiptImageUrl(request.getReceiptImageUrl())
                .purchaseDate(purchaseDate)
                .build());

        // 2. Save Budget Log (deduct from weekly food budget)
        budgetLogRepository.save(BudgetLog.builder()
                .userId(userId)
                .amount(totalFood)
                .category("FOOD")
                .note("Hóa đơn mua tại " + request.getMerchantName())
                .build());
    }

    public List<SmartLeftoverRecipeDto> getSmartLeftoversRecipes(Long userId) {
        List<PantryItem> pantry = getActivePantryItems(userId);
        List<SmartLeftoverRecipeDto> recipes = new ArrayList<>();

        // Generate customized student recipes using currently available pantry items
        boolean hasEgg = pantry.stream().anyMatch(p -> p.getCustomName().toLowerCase().contains("trứng"));
        boolean hasChicken = pantry.stream().anyMatch(p -> p.getCustomName().toLowerCase().contains("gà"));
        boolean hasTofu = pantry.stream().anyMatch(p -> p.getCustomName().toLowerCase().contains("đậu"));
        boolean hasVeggies = pantry.stream().anyMatch(p -> p.getCustomName().toLowerCase().contains("rau") || p.getCustomName().toLowerCase().contains("cải"));

        if (hasEgg && hasTofu) {
            recipes.add(SmartLeftoverRecipeDto.builder()
                    .title("Đậu phụ sốt trứng cà chua (Chảo chống dính)")
                    .cookingTime("12 phút")
                    .equipment("Chảo chống dính")
                    .ingredientsUsed(List.of("Đậu phụ Mơ", "Trứng gà", "Cà chua/Hành"))
                    .proteinG(26.5)
                    .calories(340.0)
                    .instructions(List.of(
                            "1. Cắt đậu thành miếng vuông vừa ăn, chiên sơ trên chảo chống dính 4 phút.",
                            "2. Đập 2 quả trứng gà vào bát, khuấy đều với chút gia vị.",
                            "3. Đổ trứng vào chảo đậu, đậy nắp vung nhỏ lửa 3 phút cho trứng chín xốp.",
                            "4. Rắc hành lá, dùng nóng kèm cơm hoặc ăn trực tiếp."
                    ))
                    .build());
        }

        if (hasChicken) {
            recipes.add(SmartLeftoverRecipeDto.builder()
                    .title("Ức gà áp chảo tiêu chanh nhanh gọn")
                    .cookingTime("15 phút")
                    .equipment("Chảo chống dính")
                    .ingredientsUsed(List.of("Ức gà", "Tiêu, chanh, nước mắm"))
                    .proteinG(38.0)
                    .calories(220.0)
                    .instructions(List.of(
                            "1. Thái ức gà thành lát mỏng vừa, khứa nhẹ để thấm vị.",
                            "2. Ướp nhanh với 1 thìa nước mắm, tiêu đen, tỏi băm trong 5 phút.",
                            "3. Quét một lớp dầu mỏng lên chảo chống dính, áp chảo mỗi mặt 4-5 phút cho vàng óng.",
                            "4. Vắt chút chanh lên bề mặt trước khi ăn để tăng hương vị."
                    ))
                    .build());
        }

        if (hasEgg) {
            recipes.add(SmartLeftoverRecipeDto.builder()
                    .title("Cơm trộn trứng hấp nồi cơm điện (Siêu tiết kiệm)")
                    .cookingTime("20 phút")
                    .equipment("Nồi cơm điện")
                    .ingredientsUsed(List.of("Gạo", "Trứng gà", "Nước tương, tiêu"))
                    .proteinG(18.0)
                    .calories(480.0)
                    .instructions(List.of(
                            "1. Vo gạo nấu cơm như bình thường trong nồi cơm điện.",
                            "2. Khi nồi cơm vừa bật nút Warm (hoặc còn 5 phút nữa chín), mở nắp đập 2 quả trứng trực tiếp lên mặt cơm.",
                            "3. Đậy nắp ủ thêm 7 phút để lòng đỏ lòng đào hoặc chín tới.",
                            "4. Trộn đều với 1 thìa nước tương và tiêu."
                    ))
                    .build());
        }

        // Always provide at least 2 general high-protein student recipes
        if (recipes.size() < 2) {
            recipes.add(SmartLeftoverRecipeDto.builder()
                    .title("Canh trứng cà chua đậu phụ thanh mát")
                    .cookingTime("10 phút")
                    .equipment("Nồi cơm điện hoặc nồi nhỏ")
                    .ingredientsUsed(List.of("Trứng gà", "Đậu phụ", "Cà chua", "Hành ngò"))
                    .proteinG(22.0)
                    .calories(210.0)
                    .instructions(List.of(
                            "1. Đun sôi 500ml nước cùng cà chua cắt múi cau.",
                            "2. Cho đậu phụ cắt nhỏ vào đun sôi 3 phút.",
                            "3. Đánh tan 2 quả trứng, khuấy nhẹ vòng tròn tạo vân mây.",
                            "4. Nêm gia vị vừa ăn, rắc hành ngò và thưởng thức."
                    ))
                    .build());
        }

        return recipes;
    }
}
