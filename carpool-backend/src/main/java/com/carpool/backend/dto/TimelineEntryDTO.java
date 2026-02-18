package com.carpool.backend.dto;

public class TimelineEntryDTO {
    public int sequence;
    public String time;
    public String type;
    public String studentId;
    public String shipmentLabel;
    public String visitLabel;
    public LatLngDTO location;

    public TimelineEntryDTO(int sequence, String time, String type,
                            String studentId, String shipmentLabel, String visitLabel, LatLngDTO location) {
        this.sequence = sequence;
        this.time = time;
        this.type = type;
        this.studentId = studentId;
        this.shipmentLabel = shipmentLabel;
        this.visitLabel = visitLabel;
        this.location = location;
    }

    public TimelineEntryDTO(int sequence, String time, String type,
                            String studentId, String shipmentLabel, String visitLabel) {
        this(sequence, time, type, studentId, shipmentLabel, visitLabel, null);
    }
}
