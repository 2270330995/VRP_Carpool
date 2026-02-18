package com.carpool.backend.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.carpool.backend.dto.PlaceDetails;
import com.carpool.backend.dto.PlaceSuggestion;
import com.carpool.backend.service.PlacesService;

@RestController
@RequestMapping("/api/places/legacy")
public class PlacesController {

    private final PlacesService placesService;

    public PlacesController(PlacesService placesService) {
        this.placesService = placesService;
    }

    @GetMapping("/autocomplete")
    public List<PlaceSuggestion> autocomplete(@RequestParam String input) throws Exception {
        return placesService.autocomplete(input);
    }

    @GetMapping("/details")
    public PlaceDetails details(@RequestParam String placeId) throws Exception {
        return placesService.details(placeId);
    }
}
