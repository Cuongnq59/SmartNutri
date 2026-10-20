package com.smartnutri.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "pantry_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PantryItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "ingredient_ref_id")
    private IngredientRef ingredientRef;

    @Column(nullable = false)
    private String customName; // e.g., "Ức gà WinMart", "Trứng gà Ba Huân"

    private String rawName; // Raw name from receipt if scanned

    @Column(nullable = false)
    private Double quantity; // Số lượng hiện có

    @Column(nullable = false)
    private String unit; // g, piece, pack, kg, hop, bia

    private Double costPaid; // Giá tiền đã mua (VNĐ)

    @Column(nullable = false)
    private LocalDate purchaseDate;

    private LocalDate expiryDate; // Ngày hết hạn dự kiến

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private PantryStatus status = PantryStatus.ACTIVE; // ACTIVE, CONSUMED, EXPIRED

    public enum PantryStatus {
        ACTIVE, CONSUMED, EXPIRED
    }
}
