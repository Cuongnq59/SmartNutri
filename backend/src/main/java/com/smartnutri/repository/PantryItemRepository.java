package com.smartnutri.repository;

import com.smartnutri.model.PantryItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PantryItemRepository extends JpaRepository<PantryItem, Long> {
    List<PantryItem> findByUserIdAndStatus(Long userId, PantryItem.PantryStatus status);
    List<PantryItem> findByUserIdOrderByPurchaseDateDesc(Long userId);
}
