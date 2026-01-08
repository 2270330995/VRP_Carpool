package com.carpool.backend.dto;

public class PlaceSuggestion {
    private String description;
    private String placeId;

    public PlaceSuggestion() {}

    public PlaceSuggestion(String description, String placeId) {
        this.description = description;
        this.placeId = placeId;
    }

    public String getDescription() {
        return description;
    }

    public String getPlaceId() {
        return placeId;
    }
}
