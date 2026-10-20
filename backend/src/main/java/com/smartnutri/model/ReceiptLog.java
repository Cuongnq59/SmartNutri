package com.smartnutri.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "receipt_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    private String merchantName;

    @Column(nullable = false)
    private Double totalAmount; // Tổng tiền hóa đơn

    @Column(nullable = false)
    private Double foodAmount; // Tiền thực phẩm

    @Column(columnDefinition = "TEXT")
    private String receiptImageUrl;

    @Column(nullable = false)
    private LocalDate purchaseDate;

    @Column(columnDefinition = "TEXT")
    private String itemsJson; // Raw extracted items JSON

    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
