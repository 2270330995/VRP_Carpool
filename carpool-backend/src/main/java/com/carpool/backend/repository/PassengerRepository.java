package com.carpool.backend.repository;

import com.carpool.backend.entity.PassengerEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PassengerRepository extends JpaRepository<PassengerEntity, Long> {
    List<PassengerEntity> findByActiveTrueOrActiveIsNull();
}
