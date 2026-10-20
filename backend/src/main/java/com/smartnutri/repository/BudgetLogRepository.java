package com.smartnutri.repository;

import com.smartnutri.model.BudgetLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface BudgetLogRepository extends JpaRepository<BudgetLog, Long> {
    List<BudgetLog> findByUserIdOrderByCreatedAtDesc(Long userId);
    List<BudgetLog> findByUserIdAndCreatedAtBetween(Long userId, LocalDateTime start, LocalDateTime end);
}
