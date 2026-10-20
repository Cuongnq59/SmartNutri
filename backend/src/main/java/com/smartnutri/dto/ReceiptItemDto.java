package com.smartnutri.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptItemDto {
    private String rawName;
    private String cleanName;
    private String category; // FOOD or NON_FOOD
    private Double quantity;
    private String unit; // g, piece, pack, kg, hop, bia
    private Double totalPrice;
    private Long matchedRefId;
    private String expiryDate; // YYYY-MM-DD
    @Builder.Default
    private Boolean selected = true;
}
