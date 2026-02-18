package com.carpool.backend.dto;

import java.util.List;

public class OptimizeRequestDTO {
    public EventDTO event;
    public List<DriverDTO> drivers;
    public List<StudentDTO> students;
    public String globalStartTime;
    public String globalEndTime;
    public String mode;

    public static class EventDTO {
        public LatLngDTO location;
    }

    public static class DriverDTO {
        public String id;
        public LatLngDTO home;
        public Integer seatCapacity;
    }

    public static class StudentDTO {
        public String id;
        public LatLngDTO home;
    }
}
