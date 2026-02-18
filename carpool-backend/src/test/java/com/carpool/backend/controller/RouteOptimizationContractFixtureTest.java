package com.carpool.backend.controller;

import com.carpool.backend.dto.LatLngDTO;
import com.carpool.backend.dto.OptimizeRequestDTO;
import com.carpool.backend.dto.RoutePlanDTO;
import com.carpool.backend.dto.TimelineEntryDTO;
import org.junit.jupiter.api.Test;

import java.io.InputStream;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RouteOptimizationContractFixtureTest {

    @SuppressWarnings("unchecked")
    @Test
    void buildRoutePlans_shouldParseFixtureWithStableContract() throws Exception {
        RouteOptimizationController controller = new RouteOptimizationController();
        OptimizeRequestDTO request = buildRequest();

        String fixtureJson = loadFixture("fixtures/optimizeTours_real_response.json");

        Method buildRoutePlans = RouteOptimizationController.class
                .getDeclaredMethod("buildRoutePlans", String.class, OptimizeRequestDTO.class);
        buildRoutePlans.setAccessible(true);

        List<RoutePlanDTO> plans = (List<RoutePlanDTO>) buildRoutePlans.invoke(controller, fixtureJson, request);

        assertEquals(2, plans.size());
        assertEquals("d1", plans.get(0).driverId);
        assertEquals("d2", plans.get(1).driverId);

        assertTimelineContract(plans.get(0).timeline);
        assertTimelineContract(plans.get(1).timeline);

        Set<String> route0StudentIds = plans.get(0).timeline.stream()
                .map(entry -> entry.studentId)
                .collect(Collectors.toSet());
        Set<String> route1StudentIds = plans.get(1).timeline.stream()
                .map(entry -> entry.studentId)
                .collect(Collectors.toSet());

        assertEquals(Set.of("1", "2"), route0StudentIds);
        assertEquals(Set.of("3"), route1StudentIds);

        assertEquals(2, plans.get(0).timeline.stream().filter(e -> "pickup".equals(e.type)).count());
        assertEquals(2, plans.get(0).timeline.stream().filter(e -> "dropoff".equals(e.type)).count());
        assertEquals(1, plans.get(1).timeline.stream().filter(e -> "pickup".equals(e.type)).count());
        assertEquals(1, plans.get(1).timeline.stream().filter(e -> "dropoff".equals(e.type)).count());
    }

    private static void assertTimelineContract(List<TimelineEntryDTO> timeline) {
        assertFalse(timeline.isEmpty());
        for (int i = 0; i < timeline.size(); i++) {
            TimelineEntryDTO entry = timeline.get(i);
            assertEquals(i, entry.sequence);
            assertNotNull(entry.time);
            assertNotNull(entry.type);
            assertNotNull(entry.studentId);
            assertNotNull(entry.location);
            assertNotNull(entry.location.lat);
            assertNotNull(entry.location.lng);
        }
    }

    private static String loadFixture(String path) throws Exception {
        ClassLoader classLoader = RouteOptimizationContractFixtureTest.class.getClassLoader();
        try (InputStream inputStream = classLoader.getResourceAsStream(path)) {
            assertNotNull(inputStream, "Fixture not found: " + path);
            return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private static OptimizeRequestDTO buildRequest() {
        OptimizeRequestDTO request = new OptimizeRequestDTO();

        request.event = new OptimizeRequestDTO.EventDTO();
        request.event.location = location(43.0800, -89.4000);

        OptimizeRequestDTO.DriverDTO d1 = new OptimizeRequestDTO.DriverDTO();
        d1.id = "d1";
        d1.home = location(43.0731, -89.4012);
        d1.seatCapacity = 4;

        OptimizeRequestDTO.DriverDTO d2 = new OptimizeRequestDTO.DriverDTO();
        d2.id = "d2";
        d2.home = location(43.0680, -89.3980);
        d2.seatCapacity = 3;

        request.drivers = List.of(d1, d2);

        OptimizeRequestDTO.StudentDTO s1 = new OptimizeRequestDTO.StudentDTO();
        s1.id = "1";
        s1.home = location(43.0750, -89.4100);

        OptimizeRequestDTO.StudentDTO s2 = new OptimizeRequestDTO.StudentDTO();
        s2.id = "2";
        s2.home = location(43.0700, -89.4200);

        OptimizeRequestDTO.StudentDTO s3 = new OptimizeRequestDTO.StudentDTO();
        s3.id = "3";
        s3.home = location(43.0650, -89.4050);

        request.students = List.of(s1, s2, s3);
        return request;
    }

    private static LatLngDTO location(double lat, double lng) {
        LatLngDTO loc = new LatLngDTO();
        loc.lat = lat;
        loc.lng = lng;
        return loc;
    }
}
