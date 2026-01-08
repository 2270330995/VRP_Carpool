package com.carpool.backend.dto;

import java.time.Instant;
import java.util.List;


public class RunDetailDto {
    public Long runId;
    public Instant createdAt;
    public List<DriverPlan> plans;
    //unassigned
    public int unassignedCount;
    public List<Stop> unassigned;

    public static class DriverPlan {
        public Long driverId;
        public String driverName;
        public int seats;
        public List<Stop> stops;
    }

    public static class Stop {
        public int order;
        public Long passengerId;
        public String passengerName;
        public String passengerAddress;
    }
}
