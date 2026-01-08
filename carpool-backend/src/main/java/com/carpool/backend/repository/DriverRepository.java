package com.carpool.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.carpool.backend.entity.DriverEntity;

public interface DriverRepository extends JpaRepository<DriverEntity, Long> {}
