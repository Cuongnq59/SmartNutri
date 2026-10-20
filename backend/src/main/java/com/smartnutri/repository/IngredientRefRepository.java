package com.smartnutri.repository;

import com.smartnutri.model.IngredientRef;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IngredientRefRepository extends JpaRepository<IngredientRef, Long> {
    Optional<IngredientRef> findByNameIgnoreCase(String name);
}
