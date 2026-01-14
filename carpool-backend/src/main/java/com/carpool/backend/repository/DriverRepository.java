package com.carpool.backend.repository;

import com.carpool.backend.entity.DriverEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DriverRepository extends JpaRepository<DriverEntity, Long> {
    List<DriverEntity> findByActiveTrueOrActiveIsNull();
}
