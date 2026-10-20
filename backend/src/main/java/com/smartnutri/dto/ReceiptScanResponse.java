package com.smartnutri.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptScanResponse {
    private String merchantName;
    private String purchaseDate;
    private Double totalAmount;
    private Double foodAmount;
    private List<ReceiptItemDto> items;
}
