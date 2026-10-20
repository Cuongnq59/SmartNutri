package com.smartnutri.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptScanRequest {
    private String base64Image;
    private String mimeType;
}
