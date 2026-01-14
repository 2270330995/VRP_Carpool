package com.carpool.backend.repository;

import com.carpool.backend.entity.DestinationEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DestinationRepository extends JpaRepository<DestinationEntity, Long> {
    List<DestinationEntity> findByActiveTrueOrActiveIsNull();
}
