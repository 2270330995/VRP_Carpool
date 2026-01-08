package com.carpool.backend.dto;

import java.util.List;

public class AssignResult {
    public Long driverId;
    public String driverName;
    public int seats;
    public List<Long> passengerIds;
    public List<String> passengerNames;

    public AssignResult(Long driverId, String driverName, int seats,
                        List<Long> passengerIds, List<String> passengerNames) {
        this.driverId = driverId;
        this.driverName = driverName;
        this.seats = seats;
        this.passengerIds = passengerIds;
        this.passengerNames = passengerNames;
    }
}
