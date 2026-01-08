package com.carpool.backend.repository;

import com.carpool.backend.entity.AssignmentEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssignmentRepository extends JpaRepository<AssignmentEntity, Long> {
    List<AssignmentEntity> findByRunIdOrderByDriverIdAscStopOrderAsc(Long runId);
    void deleteByRunId(Long runId);
}
