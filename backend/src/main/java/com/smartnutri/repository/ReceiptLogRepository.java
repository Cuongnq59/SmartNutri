package com.smartnutri.repository;

import com.smartnutri.model.ReceiptLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReceiptLogRepository extends JpaRepository<ReceiptLog, Long> {
    List<ReceiptLog> findByUserIdOrderByPurchaseDateDesc(Long userId);
}
