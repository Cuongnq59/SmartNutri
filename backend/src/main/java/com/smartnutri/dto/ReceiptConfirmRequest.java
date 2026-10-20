package com.smartnutri.dto;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptConfirmRequest {
    private Long userId;
    private String merchantName;
    private String purchaseDate;
    private Double totalAmount;
    private String receiptImageUrl;
    private List<ReceiptItemDto> items;
}
