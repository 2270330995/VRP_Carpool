package com.carpool.backend.service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.carpool.backend.dto.PlaceDetails;
import com.carpool.backend.dto.PlaceSuggestion;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class PlacesService {

    @Value("${google.places.api-key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper mapper = new ObjectMapper();

    public List<PlaceSuggestion> autocomplete(String input) throws Exception {
        String encoded = URLEncoder.encode(input, StandardCharsets.UTF_8);
        String url =
                "https://maps.googleapis.com/maps/api/place/autocomplete/json" +
                        "?input=" + encoded +
                        "&key=" + apiKey;

        String json = restTemplate.getForObject(url, String.class);
        JsonNode root = mapper.readTree(json);
        JsonNode predictions = root.path("predictions");

        List<PlaceSuggestion> list = new ArrayList<>();
        for (JsonNode p : predictions) {
            String description = p.path("description").asText();
            String placeId = p.path("place_id").asText();
            list.add(new PlaceSuggestion(description, placeId));
        }
        return list;
    }

    public PlaceDetails details(String placeId) throws Exception {
        String encoded = URLEncoder.encode(placeId, StandardCharsets.UTF_8);
        String url =
                "https://maps.googleapis.com/maps/api/place/details/json" +
                        "?place_id=" + encoded +
                        "&fields=formatted_address,geometry" +
                        "&key=" + apiKey;

        String json = restTemplate.getForObject(url, String.class);
        JsonNode root = mapper.readTree(json);
        JsonNode result = root.path("result");

        String address = result.path("formatted_address").asText();
        double lat = result.path("geometry").path("location").path("lat").asDouble();
        double lng = result.path("geometry").path("location").path("lng").asDouble();

        return new PlaceDetails(address, lat, lng);
    }
}
