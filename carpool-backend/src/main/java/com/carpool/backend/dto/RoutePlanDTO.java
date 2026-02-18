package com.carpool.backend.dto;

import java.util.List;
import java.util.Map;

public class RoutePlanDTO {
    public String driverId;
    public LatLngDTO driverHome;
    public LatLngDTO eventLocation;
    public List<TimelineEntryDTO> timeline;
    public Map<String, Object> metrics;

    public RoutePlanDTO(String driverId,
                        LatLngDTO driverHome,
                        LatLngDTO eventLocation,
                        List<TimelineEntryDTO> timeline,
                        Map<String, Object> metrics) {
        this.driverId = driverId;
        this.driverHome = driverHome;
        this.eventLocation = eventLocation;
        this.timeline = timeline;
        this.metrics = metrics;
    }

    public RoutePlanDTO(List<TimelineEntryDTO> timeline, Map<String, Object> metrics) {
        this.driverId = null;
        this.driverHome = null;
        this.eventLocation = null;
        this.timeline = timeline;
        this.metrics = metrics;
    }
}
