package com.smartnutri.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OptimizedItemDto {
    private String name;
    private Double portion; // serving amount (số lạng hoặc số quả/bìa)
    private String unit;
    private Double cost; // VNĐ
    private Double protein; // g
    private Double calories; // kcal
    private Boolean fromPantry; // true nếu lấy từ tủ lạnh (giá 0 VNĐ)
}
