package com.carpool.backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.carpool.backend.entity.PassengerEntity;
import com.carpool.backend.repository.PassengerRepository;

@RestController
@RequestMapping("/api/passengers")
public class PassengerController {

    private final PassengerRepository passengerRepository;

    public PassengerController(PassengerRepository passengerRepository) {
        this.passengerRepository = passengerRepository;
    }

    // GET /api/passengers
    @GetMapping
    public List<PassengerEntity> getAllPassengers(
            @RequestParam(value = "includeInactive", required = false) Boolean includeInactive
    ) {
        if (Boolean.TRUE.equals(includeInactive)) {
            return passengerRepository.findAll();
        }
        return passengerRepository.findByActiveTrueOrActiveIsNull();
    }

    // POST /api/passengers
    @PostMapping
    public PassengerEntity createPassenger(@RequestBody PassengerEntity body) {
        return passengerRepository.save(body);
    }

    // Update
    @PutMapping("/{id}")
    public PassengerEntity updatePassenger(@PathVariable Long id,
                                           @RequestBody PassengerEntity body) {
        PassengerEntity p = passengerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Passenger not found: " + id));

        p.setName(body.getName());
        p.setAddress(body.getAddress());
        p.setLat(body.getLat());
        p.setLng(body.getLng());

        return passengerRepository.save(p);
    }

    // Delete
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePassenger(@PathVariable Long id) {
        return passengerRepository.findById(id)
                .map(p -> {
                    p.setActive(false);
                    passengerRepository.save(p);
                    return ResponseEntity.noContent().build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}/restore")
    public ResponseEntity<?> restorePassenger(@PathVariable Long id) {
        return passengerRepository.findById(id)
                .map(p -> {
                    p.setActive(true);
                    passengerRepository.save(p);
                    return ResponseEntity.noContent().build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

}
