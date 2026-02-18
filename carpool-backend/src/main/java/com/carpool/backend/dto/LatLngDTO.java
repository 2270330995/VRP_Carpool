package com.carpool.backend.dto;

import com.fasterxml.jackson.annotation.JsonAlias;

public class LatLngDTO {
    @JsonAlias("latitude")
    public Double lat;

    @JsonAlias("longitude")
    public Double lng;
}
