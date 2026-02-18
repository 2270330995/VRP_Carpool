package com.carpool.backend.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

@RestController
@RequestMapping("/api/places")
public class PlacesProxyController {

    private static final String DETAILS_FIELDS = "geometry/location,formatted_address,name";

    private final RestClient restClient;

    @Value("${google.maps.api-key}")
    private String apiKey;

    public PlacesProxyController() {
        this.restClient = RestClient.builder()
                .baseUrl("https://maps.googleapis.com")
                .build();
    }

    @GetMapping(value = "/autocomplete", produces = MediaType.APPLICATION_JSON_VALUE)
    public String autocomplete(
            @RequestParam String input,
            @RequestParam String sessionToken,
            @RequestParam(required = false) String types,
            @RequestParam(required = false) String components
    ) {
        return restClient.get()
                .uri(uriBuilder -> {
                    uriBuilder.path("/maps/api/place/autocomplete/json")
                            .queryParam("input", input)
                            .queryParam("key", apiKey)
                            .queryParam("sessiontoken", sessionToken);
                    if (StringUtils.hasText(types)) {
                        uriBuilder.queryParam("types", types);
                    }
                    if (StringUtils.hasText(components)) {
                        uriBuilder.queryParam("components", components);
                    }
                    return uriBuilder.build();
                })
                .retrieve()
                .body(String.class);
    }

    @GetMapping(value = "/details", produces = MediaType.APPLICATION_JSON_VALUE)
    public String details(
            @RequestParam String placeId,
            @RequestParam String sessionToken
    ) {
        return restClient.get()
                .uri(uriBuilder -> uriBuilder.path("/maps/api/place/details/json")
                        .queryParam("place_id", placeId)
                        .queryParam("key", apiKey)
                        .queryParam("sessiontoken", sessionToken)
                        .queryParam("fields", DETAILS_FIELDS)
                        .build())
                .retrieve()
                .body(String.class);
    }
}
