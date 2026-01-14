package com.carpool.backend.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "destinations")
public class DestinationEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable=false)
    private String name;

    @Column(nullable=false)
    private String address;

    @Column
    private Boolean active = true;

    public DestinationEntity() {}

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getAddress() { return address; }
    public Boolean getActive() { return active; }

    public void setName(String name) { this.name = name; }
    public void setAddress(String address) { this.address = address; }
    public void setActive(Boolean active) { this.active = active; }
}
