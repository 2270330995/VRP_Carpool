package com.carpool.backend.controller;

import com.carpool.backend.dto.LatLngDTO;
import com.carpool.backend.dto.OptimizeRequestDTO;
import com.carpool.backend.dto.RoutePlanDTO;
import com.carpool.backend.dto.TimelineEntryDTO;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertFalse;

class RouteOptimizationMapperTest {

    private static final String GOOGLE_RESPONSE_JSON = """
            {
              "routes": [
                {
                  "vehicleIndex": 0,
                  "visits": [
                    {
                      "label": "pickup_student_11",
                      "shipmentLabel": "student_11",
                      "startTime": "2026-01-01T00:05:00Z"
                    },
                    {
                      "label": "dropoff_student_11",
                      "shipmentLabel": "student_11",
                      "startTime": "2026-01-01T00:20:00Z"
                    }
                  ],
                  "metrics": {
                    "travelDuration": "900s"
                  }
                },
                {
                  "vehicleIndex": 1,
                  "visits": [
                    {
                      "visitLabel": "pickup_student_22",
                      "shipmentLabel": "student_22",
                      "startTime": "2026-01-01T00:10:00Z"
                    },
                    {
                      "visitLabel": "dropoff_student_22",
                      "shipmentLabel": "student_22",
                      "startTime": "2026-01-01T00:27:00Z"
                    }
                  ],
                  "metrics": {
                    "travelDuration": "1020s"
                  }
                }
              ]
            }
            """;

    private static final String GOOGLE_RESPONSE_EMPTY_ROUTES_JSON = """
            {
              "routes": []
            }
            """;

    private static final String GOOGLE_RESPONSE_ROUTE_WITH_EMPTY_VISITS_JSON = """
            {
              "routes": [
                {
                  "vehicleIndex": 0
                }
              ]
            }
            """;

    private static final String GOOGLE_RESPONSE_VEHICLE_INDEX_MAPPING_JSON = """
            {
              "routes": [
                {
                  "vehicleIndex": 0,
                  "visits": [
                    {
                      "label": "pickup_student_11",
                      "shipmentLabel": "student_11",
                      "startTime": "2026-01-01T00:05:00Z"
                    }
                  ]
                }
              ]
            }
            """;

    private static final String GOOGLE_RESPONSE_FALLBACK_MAPPING_JSON = """
            {
              "routes": [
                {
                  "vehicleIndex": 99,
                  "vehicleName": "drivers/d2",
                  "visits": [
                    {
                      "label": "pickup_student_11",
                      "shipmentLabel": "student_11",
                      "startTime": "2026-01-01T00:05:00Z"
                    }
                  ]
                },
                {
                  "vehicleIndex": 99,
                  "vehicleLabel": "d1",
                  "visits": [
                    {
                      "label": "pickup_student_22",
                      "shipmentLabel": "student_22",
                      "startTime": "2026-01-01T00:08:00Z"
                    }
                  ]
                }
              ]
            }
            """;

    @SuppressWarnings("unchecked")
    @Test
    void buildRoutePlans_shouldHandleMultipleRoutes_andParseTimelineWithUnderscoreProtocol() throws Exception {
        RouteOptimizationController controller = new RouteOptimizationController();
        OptimizeRequestDTO request = buildRequest();

        Method buildRoutePlans = RouteOptimizationController.class
                .getDeclaredMethod("buildRoutePlans", String.class, OptimizeRequestDTO.class);
        buildRoutePlans.setAccessible(true);

        List<RoutePlanDTO> plans = (List<RoutePlanDTO>) buildRoutePlans.invoke(controller, GOOGLE_RESPONSE_JSON, request);

        assertEquals(2, plans.size());

        assertEquals("d1", plans.get(0).driverId);
        assertEquals(43.0731, plans.get(0).driverHome.lat);
        assertEquals(-89.4012, plans.get(0).driverHome.lng);
        assertEquals(43.0800, plans.get(0).eventLocation.lat);
        assertEquals(-89.4000, plans.get(0).eventLocation.lng);
        assertEquals("pickup", plans.get(0).timeline.get(0).type);
        assertEquals("11", plans.get(0).timeline.get(0).studentId);
        assertEquals(43.0750, plans.get(0).timeline.get(0).location.lat);
        assertEquals(-89.4100, plans.get(0).timeline.get(0).location.lng);
        assertEquals("dropoff", plans.get(0).timeline.get(1).type);
        assertEquals("11", plans.get(0).timeline.get(1).studentId);
        assertEquals(43.0800, plans.get(0).timeline.get(1).location.lat);
        assertEquals(-89.4000, plans.get(0).timeline.get(1).location.lng);

        assertEquals("d2", plans.get(1).driverId);
        assertEquals("pickup", plans.get(1).timeline.get(0).type);
        assertEquals("22", plans.get(1).timeline.get(0).studentId);
        assertEquals(43.0700, plans.get(1).timeline.get(0).location.lat);
        assertEquals(-89.4200, plans.get(1).timeline.get(0).location.lng);
        assertEquals("dropoff", plans.get(1).timeline.get(1).type);
        assertEquals("22", plans.get(1).timeline.get(1).studentId);
        assertEquals(43.0800, plans.get(1).timeline.get(1).location.lat);
        assertEquals(-89.4000, plans.get(1).timeline.get(1).location.lng);
    }

    @Test
    void inferType_and_extractStudentId_shouldFollowUnderscoreLabelConvention() throws Exception {
        Method inferType = RouteOptimizationController.class.getDeclaredMethod("inferType", String.class);
        inferType.setAccessible(true);

        Method extractStudentId = RouteOptimizationController.class
                .getDeclaredMethod("extractStudentId", String.class, String.class);
        extractStudentId.setAccessible(true);

        assertEquals("pickup", inferType.invoke(null, "pickup_student_99"));
        assertEquals("dropoff", inferType.invoke(null, "dropoff_student_99"));
        assertEquals("visit", inferType.invoke(null, "other_label"));

        assertEquals("99", extractStudentId.invoke(null, "pickup_student_99", "student_99"));
        assertEquals("77", extractStudentId.invoke(null, null, "student_77"));
        assertNull(extractStudentId.invoke(null, "invalid", null));
    }

    @SuppressWarnings("unchecked")
    @Test
    void buildRoutePlans_shouldReturnEmptyList_whenRoutesMissingOrEmpty() throws Exception {
        RouteOptimizationController controller = new RouteOptimizationController();
        OptimizeRequestDTO request = buildRequest();

        Method buildRoutePlans = RouteOptimizationController.class
                .getDeclaredMethod("buildRoutePlans", String.class, OptimizeRequestDTO.class);
        buildRoutePlans.setAccessible(true);

        List<RoutePlanDTO> plansFromMissingRoutes = (List<RoutePlanDTO>) buildRoutePlans.invoke(
                controller, "{}", request
        );
        List<RoutePlanDTO> plansFromEmptyRoutes = (List<RoutePlanDTO>) buildRoutePlans.invoke(
                controller, GOOGLE_RESPONSE_EMPTY_ROUTES_JSON, request
        );

        assertEquals(0, plansFromMissingRoutes.size());
        assertEquals(0, plansFromEmptyRoutes.size());
    }

    @SuppressWarnings("unchecked")
    @Test
    void buildRoutePlans_shouldReturnPlanWithEmptyTimeline_whenVisitsMissingOrEmpty() throws Exception {
        RouteOptimizationController controller = new RouteOptimizationController();
        OptimizeRequestDTO request = buildRequest();

        Method buildRoutePlans = RouteOptimizationController.class
                .getDeclaredMethod("buildRoutePlans", String.class, OptimizeRequestDTO.class);
        buildRoutePlans.setAccessible(true);

        List<RoutePlanDTO> plans = (List<RoutePlanDTO>) buildRoutePlans.invoke(
                controller, GOOGLE_RESPONSE_ROUTE_WITH_EMPTY_VISITS_JSON, request
        );

        assertEquals(1, plans.size());
        assertEquals("d1", plans.get(0).driverId);
        assertEquals(0, plans.get(0).timeline.size());
    }

    @SuppressWarnings("unchecked")
    @Test
    void buildRoutePlans_shouldResolveDriverFromVehicleIndex_andPopulateDriverHome() throws Exception {
        RouteOptimizationController controller = new RouteOptimizationController();
        OptimizeRequestDTO request = buildRequest();

        Method buildRoutePlans = RouteOptimizationController.class
                .getDeclaredMethod("buildRoutePlans", String.class, OptimizeRequestDTO.class);
        buildRoutePlans.setAccessible(true);

        List<RoutePlanDTO> plans = (List<RoutePlanDTO>) buildRoutePlans.invoke(
                controller, GOOGLE_RESPONSE_VEHICLE_INDEX_MAPPING_JSON, request
        );

        assertEquals(1, plans.size());
        assertEquals("d1", plans.get(0).driverId);
        assertNotNull(plans.get(0).driverHome);
        assertEquals(43.0731, plans.get(0).driverHome.lat);
        assertEquals(-89.4012, plans.get(0).driverHome.lng);
    }

    @SuppressWarnings("unchecked")
    @Test
    void buildRoutePlans_shouldResolveFallbackFromVehicleNameOrLabel_andPopulateDriverHome() throws Exception {
        RouteOptimizationController controller = new RouteOptimizationController();
        OptimizeRequestDTO request = buildRequest();

        Method buildRoutePlans = RouteOptimizationController.class
                .getDeclaredMethod("buildRoutePlans", String.class, OptimizeRequestDTO.class);
        buildRoutePlans.setAccessible(true);

        List<RoutePlanDTO> plans = (List<RoutePlanDTO>) buildRoutePlans.invoke(
                controller, GOOGLE_RESPONSE_FALLBACK_MAPPING_JSON, request
        );

        assertEquals(2, plans.size());

        assertEquals("d2", plans.get(0).driverId);
        assertNotNull(plans.get(0).driverHome);
        assertEquals(43.0680, plans.get(0).driverHome.lat);
        assertEquals(-89.3980, plans.get(0).driverHome.lng);

        assertEquals("d1", plans.get(1).driverId);
        assertNotNull(plans.get(1).driverHome);
        assertEquals(43.0731, plans.get(1).driverHome.lat);
        assertEquals(-89.4012, plans.get(1).driverHome.lng);
    }

    @Test
    void assignStudentsGreedy_shouldRespectSeatCapacity() {
        OptimizeRequestDTO request = buildRequest();
        request.drivers.get(0).seatCapacity = 1;
        request.drivers.get(1).seatCapacity = 2;

        Map<String, List<OptimizeRequestDTO.StudentDTO>> assignments = RouteOptimizationController.assignStudentsGreedy(
                request.drivers,
                request.students,
                request.event.location
        );

        assertTrue(assignments.get("d1").size() <= 1);
        assertTrue(assignments.get("d2").size() <= 2);
    }

    @Test
    void hasSeatCapacityViolation_shouldReturnTrue_whenPickupCountExceedsCapacity() {
        OptimizeRequestDTO request = buildRequest();
        request.drivers.get(0).seatCapacity = 2;

        List<TimelineEntryDTO> timeline = new ArrayList<>();
        timeline.add(new TimelineEntryDTO(0, "2026-01-01T00:01:00Z", "pickup", "11", "s11", "pickup_student_11", null));
        timeline.add(new TimelineEntryDTO(1, "2026-01-01T00:02:00Z", "pickup", "22", "s22", "pickup_student_22", null));
        timeline.add(new TimelineEntryDTO(2, "2026-01-01T00:03:00Z", "pickup", "33", "s33", "pickup_student_33", null));

        List<RoutePlanDTO> plans = List.of(new RoutePlanDTO("d1", null, null, timeline, Map.of()));

        assertTrue(RouteOptimizationController.hasSeatCapacityViolation(plans, request));
    }

    @Test
    void hasSeatCapacityViolation_shouldReturnFalse_whenPickupCountWithinCapacity() {
        OptimizeRequestDTO request = buildRequest();
        request.drivers.get(0).seatCapacity = 3;

        List<TimelineEntryDTO> timeline = new ArrayList<>();
        timeline.add(new TimelineEntryDTO(0, "2026-01-01T00:01:00Z", "pickup", "11", "s11", "pickup_student_11", null));
        timeline.add(new TimelineEntryDTO(1, "2026-01-01T00:02:00Z", "pickup", "22", "s22", "pickup_student_22", null));

        List<RoutePlanDTO> plans = List.of(new RoutePlanDTO("d1", null, null, timeline, Map.of()));

        assertFalse(RouteOptimizationController.hasSeatCapacityViolation(plans, request));
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
        OptimizeRequestDTO.StudentDTO s11 = new OptimizeRequestDTO.StudentDTO();
        s11.id = "11";
        s11.home = location(43.0750, -89.4100);

        OptimizeRequestDTO.StudentDTO s22 = new OptimizeRequestDTO.StudentDTO();
        s22.id = "22";
        s22.home = location(43.0700, -89.4200);

        request.students = List.of(s11, s22);
        return request;
    }

    private static LatLngDTO location(double lat, double lng) {
        LatLngDTO loc = new LatLngDTO();
        loc.lat = lat;
        loc.lng = lng;
        return loc;
    }
}
