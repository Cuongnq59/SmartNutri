package com.smartnutri.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "local_ingredients_ref")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IngredientRef {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String aliases;

    @Column(name = "avg_price_vnd")
    private Double avgPriceVnd;

    @Column(name = "standard_unit")
    private String standardUnit;

    @Column(name = "standard_weight_g")
    private Double standardWeightG;

    @Column(name = "protein_per_100g")
    private Double proteinPer100g;

    @Column(name = "calories_per_100g")
    private Double caloriesPer100g;

    @Column(name = "carbs_per_100g")
    private Double carbsPer100g;

    @Column(name = "fat_per_100g")
    private Double fatPer100g;

    @Column(name = "is_discrete")
    private Boolean isDiscrete;

    @Column(name = "max_portion")
    private Double maxPortion;

    @Column(name = "default_shelf_life_days")
    private Integer defaultShelfLifeDays;

    private String category;
}
