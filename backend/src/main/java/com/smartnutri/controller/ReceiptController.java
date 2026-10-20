package com.smartnutri.controller;

import com.smartnutri.dto.ReceiptConfirmRequest;
import com.smartnutri.dto.ReceiptScanRequest;
import com.smartnutri.dto.ReceiptScanResponse;
import com.smartnutri.service.PantryService;
import com.smartnutri.service.ReceiptOcrService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/receipts")
public class ReceiptController {

    private final ReceiptOcrService receiptOcrService;
    private final PantryService pantryService;

    public ReceiptController(ReceiptOcrService receiptOcrService, PantryService pantryService) {
        this.receiptOcrService = receiptOcrService;
        this.pantryService = pantryService;
    }

    @PostMapping("/scan")
    public ResponseEntity<ReceiptScanResponse> scanReceipt(@RequestBody ReceiptScanRequest request) {
        ReceiptScanResponse response = receiptOcrService.scanReceipt(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/confirm")
    public ResponseEntity<?> confirmReceipt(@RequestBody ReceiptConfirmRequest request) {
        pantryService.confirmReceiptToPantry(request);
        return ResponseEntity.ok(Map.of("message", "Đã lưu hóa đơn và cập nhật nguyên liệu vào Tủ lạnh ảo thành công!"));
    }
}
