package com.carpool.backend.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "assignment_runs")
public class AssignmentRunEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    // 可选：备注（比如“周三早上”）
    private String note;

    public AssignmentRunEntity() {}

    public Long getId() { return id; }
    public Instant getCreatedAt() { return createdAt; }
    public String getNote() { return note; }

    public void setNote(String note) { this.note = note; }
}
