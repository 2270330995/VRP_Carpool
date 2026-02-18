package com.carpool.backend.controller;

import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.GoogleCredentials;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.carpool.backend.dto.LatLngDTO;
import com.carpool.backend.dto.OptimizeRequestDTO;
import com.carpool.backend.dto.RoutePlanDTO;
import com.carpool.backend.dto.TimelineEntryDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/optimize")
public class RouteOptimizationController {

    private static final Logger log = LoggerFactory.getLogger(RouteOptimizationController.class);
    private static final String MODE_GLOBAL_MIN_TIME = "GLOBAL_MIN_TIME";
    private static final String MODE_PER_VEHICLE_MIN_TIME = "PER_VEHICLE_MIN_TIME";
    private static final DateTimeFormatter UTC_SECONDS_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'").withZone(ZoneOffset.UTC);
    private final RestClient rest;
    private final ObjectMapper mapper = new ObjectMapper();

    @Value("${google.gcp.project-id}")
    private String projectId;

    // 简单缓存 token（避免每次都刷新）
    private volatile AccessToken cachedToken;

    public RouteOptimizationController() {
        this.rest = RestClient.builder()
                .baseUrl("https://routeoptimization.googleapis.com")
                .build();
    }

    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE, consumes = MediaType.APPLICATION_JSON_VALUE)
    public List<RoutePlanDTO> optimize(@RequestBody OptimizeRequestDTO request) throws IOException {
        validateRequest(request);
        return executeOptimization(request);
    }

    @PostMapping(value = "/test", produces = MediaType.APPLICATION_JSON_VALUE)
    public List<RoutePlanDTO> testOptimize() throws IOException {
        OptimizeRequestDTO request = new OptimizeRequestDTO();
        request.event = new OptimizeRequestDTO.EventDTO();
        request.event.location = location(43.0800, -89.4000);
        request.drivers = List.of(
                driver("1", 43.0731, -89.4012, 4)
        );
        request.students = List.of(
                student("1", 43.0750, -89.4100),
                student("2", 43.0700, -89.4200),
                student("3", 43.0650, -89.4050)
        );
        request.globalStartTime = "2026-01-01T00:00:00Z";
        request.globalEndTime = "2026-01-01T06:00:00Z";

        return executeOptimization(request);
    }

    private List<RoutePlanDTO> executeOptimization(OptimizeRequestDTO request) throws IOException {
        String token = getAccessToken();
        if (isPerVehicleMode(request.mode)) {
            return executePerVehicleOptimization(request, token);
        }

        Map<String, Object> body = buildOptimizeBody(
                request.event.location,
                request.drivers,
                request.students,
                request.globalStartTime,
                request.globalEndTime
        );
        String response = callOptimizeTours(token, body);
        List<RoutePlanDTO> plans = buildRoutePlans(response, request);
        if (hasSeatCapacityViolation(plans, request)) {
            log.warn("Detected seat-capacity violation from global optimize result. Falling back to PER_VEHICLE_MIN_TIME.");
            return executePerVehicleOptimization(request, token);
        }
        return plans;
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

    private static OptimizeRequestDTO.DriverDTO driver(String id, double lat, double lng, int seats) {
        OptimizeRequestDTO.DriverDTO driver = new OptimizeRequestDTO.DriverDTO();
        driver.id = id;
        driver.home = location(lat, lng);
        driver.seatCapacity = seats;
        return driver;
    }

    private static OptimizeRequestDTO.StudentDTO student(String id, double lat, double lng) {
        OptimizeRequestDTO.StudentDTO student = new OptimizeRequestDTO.StudentDTO();
        student.id = id;
        student.home = location(lat, lng);
        return student;
    }

    private static LatLngDTO location(double lat, double lng) {
        LatLngDTO location = new LatLngDTO();
        location.lat = lat;
        location.lng = lng;
        return location;
    }

    private List<RoutePlanDTO> executePerVehicleOptimization(OptimizeRequestDTO request, String token) throws IOException {
        Map<String, List<OptimizeRequestDTO.StudentDTO>> assignments = assignStudentsGreedy(
                request.drivers,
                request.students,
                request.event.location
        );

        List<RoutePlanDTO> merged = new ArrayList<>();
        for (OptimizeRequestDTO.DriverDTO driver : request.drivers) {
            List<OptimizeRequestDTO.StudentDTO> assigned = assignments.get(driver.id);
            if (assigned == null || assigned.isEmpty()) {
                continue;
            }

            OptimizeRequestDTO driverScopedRequest = new OptimizeRequestDTO();
            driverScopedRequest.event = request.event;
            driverScopedRequest.drivers = List.of(driver);
            driverScopedRequest.students = assigned;
            driverScopedRequest.globalStartTime = request.globalStartTime;
            driverScopedRequest.globalEndTime = request.globalEndTime;
            driverScopedRequest.mode = MODE_GLOBAL_MIN_TIME;

            Map<String, Object> body = buildOptimizeBody(
                    request.event.location,
                    driverScopedRequest.drivers,
                    driverScopedRequest.students,
                    request.globalStartTime,
                    request.globalEndTime
            );
            String response = callOptimizeTours(token, body);
            merged.addAll(buildRoutePlans(response, driverScopedRequest));
        }
        return merged;
    }

    private String callOptimizeTours(String token, Map<String, Object> body) throws IOException {
        log.info("Route optimization request body: {}", mapper.writeValueAsString(body));
        return rest.post()
                .uri("/v1/projects/{projectId}:optimizeTours", projectId)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(String.class);
    }

    private Map<String, Object> buildOptimizeBody(LatLngDTO eventLocation,
                                                  List<OptimizeRequestDTO.DriverDTO> drivers,
                                                  List<OptimizeRequestDTO.StudentDTO> students,
                                                  String globalStartTime,
                                                  String globalEndTime) {
        List<Map<String, Object>> vehicles = new ArrayList<>();
        for (OptimizeRequestDTO.DriverDTO driver : drivers) {
            vehicles.add(Map.of(
                    "name", "drivers/" + driver.id,
                    "label", driver.id,
                    "startLocation", latLng(driver.home),
                    "endLocation", latLng(eventLocation),
                    "loadLimits", Map.of(
                            "seats", Map.of("maxLoad", String.valueOf(driver.seatCapacity))
                    )
            ));
        }

        List<Map<String, Object>> shipments = new ArrayList<>();
        for (OptimizeRequestDTO.StudentDTO student : students) {
            shipments.add(Map.of(
                    "name", "students/" + student.id,
                    "loadDemands", Map.of(
                            "seats", Map.of("amount", "1")
                    ),
                    "pickups", List.of(
                            Map.of(
                                    "arrivalLocation", latLng(student.home),
                                    "label", "pickup_student_" + student.id
                            )
                    ),
                    "deliveries", List.of(
                            Map.of(
                                    "arrivalLocation", latLng(eventLocation),
                                    "label", "dropoff_student_" + student.id
                            )
                    )
            ));
        }

        Map<String, Object> model = new LinkedHashMap<>();
        model.put("vehicles", vehicles);
        model.put("shipments", shipments);
        model.put("objectives", List.of(
                Map.of("type", "MIN_TRAVEL_TIME")
        ));
        if (!isBlank(globalStartTime)) {
            model.put("globalStartTime", normalizeUtcTimestamp(globalStartTime));
        }
        if (!isBlank(globalEndTime)) {
            model.put("globalEndTime", normalizeUtcTimestamp(globalEndTime));
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", model);
        body.put("searchMode", "RETURN_FAST");
        return body;
    }

    static Map<String, List<OptimizeRequestDTO.StudentDTO>> assignStudentsGreedy(
            List<OptimizeRequestDTO.DriverDTO> drivers,
            List<OptimizeRequestDTO.StudentDTO> students,
            LatLngDTO eventLocation
    ) {
        Map<String, List<OptimizeRequestDTO.StudentDTO>> assignments = new LinkedHashMap<>();
        Map<String, Integer> remainingSeats = new LinkedHashMap<>();
        List<String> unassignedStudentIds = new ArrayList<>();
        for (OptimizeRequestDTO.DriverDTO driver : drivers) {
            assignments.put(driver.id, new ArrayList<>());
            remainingSeats.put(driver.id, driver.seatCapacity);
        }

        List<OptimizeRequestDTO.StudentDTO> sortedStudents = new ArrayList<>(students);
        sortedStudents.sort((left, right) -> Double.compare(
                minAssignmentCost(right, drivers, eventLocation),
                minAssignmentCost(left, drivers, eventLocation)
        ));

        for (OptimizeRequestDTO.StudentDTO student : sortedStudents) {
            OptimizeRequestDTO.DriverDTO bestDriver = null;
            double bestCost = Double.MAX_VALUE;

            for (OptimizeRequestDTO.DriverDTO driver : drivers) {
                Integer seatsLeft = remainingSeats.get(driver.id);
                if (seatsLeft == null || seatsLeft <= 0) {
                    continue;
                }
                double cost = assignmentCost(driver.home, student.home, eventLocation);
                if (cost < bestCost) {
                    bestCost = cost;
                    bestDriver = driver;
                }
            }

            if (bestDriver == null) {
                unassignedStudentIds.add(student.id);
                continue;
            }

            assignments.get(bestDriver.id).add(student);
            remainingSeats.put(bestDriver.id, remainingSeats.get(bestDriver.id) - 1);
        }

        if (!unassignedStudentIds.isEmpty()) {
            log.warn("Unassigned students due to seat limits: {}", unassignedStudentIds);
        }

        return assignments;
    }

    private static double minAssignmentCost(OptimizeRequestDTO.StudentDTO student,
                                            List<OptimizeRequestDTO.DriverDTO> drivers,
                                            LatLngDTO eventLocation) {
        double best = Double.MAX_VALUE;
        for (OptimizeRequestDTO.DriverDTO driver : drivers) {
            best = Math.min(best, assignmentCost(driver.home, student.home, eventLocation));
        }
        return best;
    }

    private static double assignmentCost(LatLngDTO driverHome, LatLngDTO studentHome, LatLngDTO eventLocation) {
        return haversineKm(driverHome, studentHome) + haversineKm(studentHome, eventLocation);
    }

    private static double haversineKm(LatLngDTO a, LatLngDTO b) {
        final double earthRadiusKm = 6371.0088;
        double lat1 = Math.toRadians(a.lat);
        double lat2 = Math.toRadians(b.lat);
        double dLat = lat2 - lat1;
        double dLng = Math.toRadians(b.lng - a.lng);
        double h = Math.pow(Math.sin(dLat / 2), 2)
                + Math.cos(lat1) * Math.cos(lat2) * Math.pow(Math.sin(dLng / 2), 2);
        double c = 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
        return earthRadiusKm * c;
    }

    private static boolean isPerVehicleMode(String mode) {
        return MODE_PER_VEHICLE_MIN_TIME.equalsIgnoreCase(mode);
    }

    static boolean hasSeatCapacityViolation(List<RoutePlanDTO> plans, OptimizeRequestDTO request) {
        Map<String, Integer> capacityByDriverId = new HashMap<>();
        for (OptimizeRequestDTO.DriverDTO driver : request.drivers) {
            capacityByDriverId.put(driver.id, driver.seatCapacity);
        }

        for (RoutePlanDTO plan : plans) {
            String driverId = plan.driverId;
            if (isBlank(driverId)) {
                continue;
            }
            Integer capacity = capacityByDriverId.get(driverId);
            if (capacity == null) {
                continue;
            }

            Set<String> uniquePickups = new HashSet<>();
            for (TimelineEntryDTO entry : plan.timeline) {
                if ("pickup".equals(entry.type) && !isBlank(entry.studentId)) {
                    uniquePickups.add(entry.studentId);
                }
            }
            if (uniquePickups.size() > capacity) {
                return true;
            }
        }

        return false;
    }

    static String normalizeUtcTimestamp(String value) {
        Instant instant = Instant.parse(value);
        Instant truncated = instant.truncatedTo(ChronoUnit.SECONDS);
        return UTC_SECONDS_FORMATTER.format(truncated);
    }

    private static Map<String, Object> latLng(LatLngDTO location) {
        return Map.of("latitude", location.lat, "longitude", location.lng);
    }

    private List<RoutePlanDTO> buildRoutePlans(String responseJson, OptimizeRequestDTO request) throws IOException {
        JsonNode root = mapper.readTree(responseJson);
        JsonNode routes = root.path("routes");

        Map<String, String> vehicleNameToDriverId = new LinkedHashMap<>();
        for (OptimizeRequestDTO.DriverDTO driver : request.drivers) {
            vehicleNameToDriverId.put("drivers/" + driver.id, driver.id);
            vehicleNameToDriverId.put(driver.id, driver.id);
        }

        Map<String, LatLngDTO> studentHomeById = new LinkedHashMap<>();
        for (OptimizeRequestDTO.StudentDTO student : request.students) {
            studentHomeById.put(student.id, student.home);
        }

        List<RoutePlanDTO> plans = new ArrayList<>();
        if (routes.isArray()) {
            int routeOrder = 0;
            for (JsonNode route : routes) {
                JsonNode visits = route.path("visits");

                List<TimelineEntryDTO> timeline = new ArrayList<>();
                if (visits.isArray()) {
                    int sequence = 0;
                    for (JsonNode visit : visits) {
                        String visitLabel = firstNonBlank(
                                visit.path("label").asText(null),
                                visit.path("visitLabel").asText(null)
                        );
                        String shipmentLabel = visit.path("shipmentLabel").asText(null);
                        String time = visit.path("startTime").asText(null);
                        if (isBlank(visitLabel) || isBlank(time)) {
                            log.warn("Skipping visit due to missing required fields. label={}, startTime={}", visitLabel, time);
                            continue;
                        }
                        String type = inferType(visitLabel);
                        String studentId = extractStudentId(visitLabel, shipmentLabel);

                        timeline.add(new TimelineEntryDTO(
                                sequence++,
                                time,
                                type,
                                studentId,
                                shipmentLabel,
                                visitLabel,
                                resolveVisitLocation(
                                        type,
                                        studentId,
                                        studentHomeById,
                                        request.event.location
                                )
                        ));
                    }
                }

                Map<String, Object> metrics = mapper.convertValue(
                        route.path("metrics"),
                        new TypeReference<Map<String, Object>>() {}
                );
                if (metrics == null) {
                    metrics = Map.of();
                }

                int vehicleIndex = route.path("vehicleIndex").asInt(-1);
                String vehicleName = route.path("vehicleName").asText(null);
                String vehicleLabel = route.path("vehicleLabel").asText(null);
                LatLngDTO driverHome = resolveDriverHome(
                        vehicleIndex,
                        vehicleName,
                        vehicleLabel,
                        request,
                        vehicleNameToDriverId
                );
                String driverId = resolveDriverId(
                        vehicleIndex,
                        vehicleName,
                        vehicleLabel,
                        request,
                        vehicleNameToDriverId,
                        routeOrder
                );
                log.debug(
                        "Route mapping resolved. vehicleIndex={}, vehicleName={}, vehicleLabel={}, driverId={}",
                        vehicleIndex,
                        vehicleName,
                        vehicleLabel,
                        driverId
                );
                plans.add(new RoutePlanDTO(
                        driverId,
                        driverHome,
                        copyLocation(request.event.location),
                        timeline,
                        metrics
                ));
                routeOrder++;
            }
        }

        return plans;
    }

    private String resolveDriverId(int vehicleIndex,
                                   String vehicleName,
                                   String vehicleLabel,
                                   OptimizeRequestDTO request,
                                   Map<String, String> vehicleNameToDriverId,
                                   int routeOrder) {
        if (vehicleIndex >= 0 && vehicleIndex < request.drivers.size()) {
            return request.drivers.get(vehicleIndex).id;
        }
        if (vehicleIndex >= 0) {
            log.warn("Route vehicleIndex {} out of range for {} drivers", vehicleIndex, request.drivers.size());
        }

        if (!isBlank(vehicleName)) {
            String driverId = vehicleNameToDriverId.get(vehicleName);
            if (driverId != null) {
                return driverId;
            }
        }

        if (!isBlank(vehicleLabel)) {
            String driverId = vehicleNameToDriverId.get(vehicleLabel);
            if (driverId != null) {
                return driverId;
            }
        }

        String fallbackDriverId = "unknown_driver_" + (routeOrder + 1);
        log.warn("Unable to resolve driverId for route. vehicleIndex={}, vehicleName={}, vehicleLabel={}",
                vehicleIndex, vehicleName, vehicleLabel);
        return fallbackDriverId;
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private static String firstNonBlank(String first, String second) {
        if (!isBlank(first)) {
            return first;
        }
        return second;
    }

    private void validateRequest(OptimizeRequestDTO request) {
        if (request == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Request body is required");
        }
        if (request.event == null || request.event.location == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "event.location is required");
        }
        validateLocation(request.event.location, "event.location");

        if (request.drivers == null || request.drivers.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "drivers must not be empty");
        }
        for (int i = 0; i < request.drivers.size(); i++) {
            OptimizeRequestDTO.DriverDTO driver = request.drivers.get(i);
            if (driver == null || isBlank(driver.id)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "drivers[" + i + "].id is required");
            }
            if (driver.home == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "drivers[" + i + "].home is required");
            }
            validateLocation(driver.home, "drivers[" + i + "].home");
            if (driver.seatCapacity == null || driver.seatCapacity <= 0) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "drivers[" + i + "].seatCapacity must be > 0");
            }
        }

        if (request.students == null || request.students.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "students must not be empty");
        }
        for (int i = 0; i < request.students.size(); i++) {
            OptimizeRequestDTO.StudentDTO student = request.students.get(i);
            if (student == null || isBlank(student.id)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "students[" + i + "].id is required");
            }
            if (student.home == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "students[" + i + "].home is required");
            }
            validateLocation(student.home, "students[" + i + "].home");
        }
    }

    private static void validateLocation(LatLngDTO location, String fieldPath) {
        if (location.lat == null || location.lng == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, fieldPath + ".lat/lng are required");
        }
    }

    private static String inferType(String visitLabel) {
        if (visitLabel == null) {
            return "visit";
        }
        if (visitLabel.startsWith("pickup_")) {
            return "pickup";
        }
        if (visitLabel.startsWith("dropoff_")) {
            return "dropoff";
        }
        return "visit";
    }

    private static String extractStudentId(String visitLabel, String shipmentLabel) {
        String label = visitLabel != null ? visitLabel : shipmentLabel;
        if (label == null) {
            return null;
        }
        int idx = label.lastIndexOf('_');
        if (idx < 0 || idx == label.length() - 1) {
            return null;
        }
        return label.substring(idx + 1);
    }

    private static LatLngDTO resolveVisitLocation(String type,
                                                  String studentId,
                                                  Map<String, LatLngDTO> studentHomeById,
                                                  LatLngDTO eventLocation) {
        if ("pickup".equals(type)) {
            return copyLocation(studentHomeById.get(studentId));
        }
        if ("dropoff".equals(type)) {
            return copyLocation(eventLocation);
        }
        return null;
    }

    private static LatLngDTO copyLocation(LatLngDTO source) {
        if (source == null) {
            return null;
        }
        LatLngDTO copy = new LatLngDTO();
        copy.lat = source.lat;
        copy.lng = source.lng;
        return copy;
    }

    private static LatLngDTO resolveDriverHome(int vehicleIndex,
                                               String vehicleName,
                                               String vehicleLabel,
                                               OptimizeRequestDTO request,
                                               Map<String, String> vehicleNameToDriverId) {
        if (vehicleIndex >= 0 && vehicleIndex < request.drivers.size()) {
            return copyLocation(request.drivers.get(vehicleIndex).home);
        }
        String driverId = null;
        if (!isBlank(vehicleName)) {
            driverId = vehicleNameToDriverId.get(vehicleName);
        }
        if (isBlank(driverId) && !isBlank(vehicleLabel)) {
            driverId = vehicleNameToDriverId.get(vehicleLabel);
        }
        if (!isBlank(driverId)) {
            for (OptimizeRequestDTO.DriverDTO driver : request.drivers) {
                if (driverId.equals(driver.id)) {
                    return copyLocation(driver.home);
                }
            }
        }
        return null;
    }
}
