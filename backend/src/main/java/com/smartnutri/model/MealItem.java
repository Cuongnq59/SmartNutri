package com.smartnutri.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "meal_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MealItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meal_id")
    @JsonBackReference
    private Meal meal;

    private String itemName;
    private Double weightG;
    private Double calories;
    private Double protein;
    private Double carbs;
    private Double fat;

    @JsonProperty("name")
    public void setName(String name) {
        if (this.itemName == null || this.itemName.isBlank()) {
            this.itemName = name;
        }
    }

    @JsonProperty("estimated_weight_g")
    public void setEstimatedWeightG(Double weight) {
        if (this.weightG == null) {
            this.weightG = weight;
        }
    }

    @JsonProperty("protein_g")
    public void setProteinG(Double p) {
        if (this.protein == null) {
            this.protein = p;
        }
    }

    @JsonProperty("carbs_g")
    public void setCarbsG(Double c) {
        if (this.carbs == null) {
            this.carbs = c;
        }
    }

    @JsonProperty("fat_g")
    public void setFatG(Double f) {
        if (this.fat == null) {
            this.fat = f;
        }
    }
}
