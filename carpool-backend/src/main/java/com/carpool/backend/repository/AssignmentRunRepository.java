package com.carpool.backend.repository;

import com.carpool.backend.entity.AssignmentRunEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AssignmentRunRepository extends JpaRepository<AssignmentRunEntity, Long> {
    AssignmentRunEntity findTopByOrderByCreatedAtDesc();
}
