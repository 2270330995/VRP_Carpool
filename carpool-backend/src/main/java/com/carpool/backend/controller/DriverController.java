package com.carpool.backend.controller;

import java.util.List;

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
    public List<DriverEntity> getAllDrivers() {
        return driverRepository.findAll();
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

        return driverRepository.save(d);
    }

    @DeleteMapping("/{id}")
    public void deleteDriver(@PathVariable Long id) {
        driverRepository.deleteById(id);
    }

}
