package com.carpool.backend.controller;

import com.carpool.backend.entity.DestinationEntity;
import com.carpool.backend.repository.DestinationRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/destinations")
public class DestinationController {

    private final DestinationRepository repo;

    public DestinationController(DestinationRepository repo) {
        this.repo = repo;
    }

    @GetMapping
    public List<DestinationEntity> list(
            @RequestParam(value = "includeInactive", required = false) Boolean includeInactive
    ) {
        if (Boolean.TRUE.equals(includeInactive)) {
            return repo.findAll();
        }
        return repo.findByActiveTrueOrActiveIsNull();
    }

    @PostMapping
    public DestinationEntity create(@RequestBody DestinationEntity body) {
        return repo.save(body);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody DestinationEntity body) {
        return repo.findById(id)
                .map(d -> {
                    d.setName(body.getName());
                    d.setAddress(body.getAddress());
                    return ResponseEntity.ok(repo.save(d));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        return repo.findById(id)
                .map(d -> {
                    d.setActive(false);
                    repo.save(d);
                    return ResponseEntity.noContent().build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}/restore")
    public ResponseEntity<?> restore(@PathVariable Long id) {
        return repo.findById(id)
                .map(d -> {
                    d.setActive(true);
                    repo.save(d);
                    return ResponseEntity.noContent().build();
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
