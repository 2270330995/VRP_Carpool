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
    public List<DestinationEntity> list() {
        return repo.findAll();
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
        if (!repo.existsById(id)) return ResponseEntity.notFound().build();
        repo.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
