package com.carpool.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "drivers")
public class DriverEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable=false)
    private String name;

    private String carModel;

    @Column(nullable=false)
    private Integer seats;

    @Column(nullable=false)
    private String address;

    public DriverEntity() {}

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getCarModel() { return carModel; }
    public Integer getSeats() { return seats; }
    public String getAddress() { return address; }

    public void setName(String name) { this.name = name; }
    public void setCarModel(String carModel) { this.carModel = carModel; }
    public void setSeats(Integer seats) { this.seats = seats; }
    public void setAddress(String address) { this.address = address; }
}
