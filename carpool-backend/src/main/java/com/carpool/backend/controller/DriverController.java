package com.carpool.backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.carpool.backend.entity.DriverEntity;
import com.carpool.backend.repository.DriverRepository;

@RestController
@RequestMapping("/api/drivers")
public class DriverController {

    private final DriverRepository driverRepository;

    public DriverController(DriverRepository driverRepository) {
        this.driverRepository = driverRepository;
    }

    @GetMapping
    public List<DriverEntity> getAllDrivers(
            @RequestParam(value = "includeInactive", required = false) Boolean includeInactive
    ) {
        if (Boolean.TRUE.equals(includeInactive)) {
            return driverRepository.findAll();
        }
        return driverRepository.findByActiveTrueOrActiveIsNull();
    }

    @PostMapping
    public DriverEntity createDriver(@RequestBody DriverEntity body) {
        return driverRepository.save(body);
    }

    @PutMapping("/{id}")
    public DriverEntity updateDriver(@PathVariable Long id,
                                     @RequestBody DriverEntity body) {
        DriverEntity d = driverRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Driver not found: " + id));

        d.setName(body.getName());
        d.setCarModel(body.getCarModel());
        d.setSeats(body.getSeats());
        d.setAddress(body.getAddress());
        d.setLat(body.getLat());
        d.setLng(body.getLng());

        return driverRepository.save(d);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteDriver(@PathVariable Long id) {
        return driverRepository.findById(id)
                .map(d -> {
                    d.setActive(false);
                    driverRepository.save(d);
                    return ResponseEntity.noContent().build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}/restore")
    public ResponseEntity<?> restoreDriver(@PathVariable Long id) {
        return driverRepository.findById(id)
                .map(d -> {
                    d.setActive(true);
                    driverRepository.save(d);
                    return ResponseEntity.noContent().build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

}
