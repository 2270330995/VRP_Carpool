package com.carpool.backend.dto;

public class PlaceDetails {
    private String address;
    private double lat;
    private double lng;

    public PlaceDetails() {}

    public PlaceDetails(String address, double lat, double lng) {
        this.address = address;
        this.lat = lat;
        this.lng = lng;
    }

    public String getAddress() {
        return address;
    }

    public double getLat() {
        return lat;
    }

    public double getLng() {
        return lng;
    }
}
