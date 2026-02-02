package com.carpool.backend.controller;

import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.GoogleCredentials;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/optimize")
public class RouteOptimizationController {

    private final RestClient rest;

    @Value("${google.gcp.project-id}")
    private String projectId;

    // 简单缓存 token（避免每次都刷新）
    private volatile AccessToken cachedToken;

    public RouteOptimizationController() {
        this.rest = RestClient.builder()
                .baseUrl("https://routeoptimization.googleapis.com")
                .build();
    }

    @PostMapping(value = "/test", produces = MediaType.APPLICATION_JSON_VALUE)
    public String testOptimize() throws IOException {

        String token = getAccessToken();

        Map<String, Object> body = Map.of(
                "model", Map.of(
                        "vehicles", List.of(
                                Map.of(
                                        "name", "drivers/1",
                                        "startLocation", latLng(43.0731, -89.4012),
                                        "endLocation", latLng(43.0731, -89.4012)
                                )
                        ),
                        "shipments", List.of(
                                shipment("p1", 43.0760, -89.4020)
                        ),
                        "globalStartTime", "2026-01-01T00:00:00Z",
                        "globalEndTime", "2026-01-01T06:00:00Z"
                ),
                "searchMode", "RETURN_FAST"
        );

        return rest.post()
                .uri("/v1/projects/{projectId}:optimizeTours", projectId)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(String.class);
    }

    private String getAccessToken() throws IOException {
        // token 还有效就复用（提前 60s 刷新）
        if (cachedToken != null && cachedToken.getExpirationTime() != null) {
            Instant exp = cachedToken.getExpirationTime().toInstant();
            if (exp.isAfter(Instant.now().plusSeconds(60))) {
                return cachedToken.getTokenValue();
            }
        }

        GoogleCredentials creds = GoogleCredentials.getApplicationDefault()
                .createScoped(List.of("https://www.googleapis.com/auth/cloud-platform"));

        // 兼容不同版本 auth library：没有 refreshIfExpired 就用 refreshAccessToken
        AccessToken token = creds.refreshAccessToken();
        cachedToken = token;
        return token.getTokenValue();
    }

    private static Map<String, Object> latLng(double lat, double lng) {
        return Map.of("latitude", lat, "longitude", lng);
    }

    private static Map<String, Object> shipment(String name, double lat, double lng) {
        return Map.of(
                "name", name,
                "deliveries", List.of(
                        Map.of("arrivalLocation", latLng(lat, lng))
                )
        );
    }
}
