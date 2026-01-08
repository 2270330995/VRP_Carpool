package com.carpool.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.carpool.backend.entity.PassengerEntity;

public interface PassengerRepository extends JpaRepository<PassengerEntity, Long> {}
