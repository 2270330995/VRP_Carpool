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
    public List<PassengerEntity> getAllPassengers() {
        return passengerRepository.findAll();
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

        return passengerRepository.save(p);
    }

    // Delete
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePassenger(@PathVariable Long id) {
        if (!passengerRepository.existsById(id)) return ResponseEntity.notFound().build();
        passengerRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }


}
