package com.carpool.backend.controller;

import com.carpool.backend.dto.LatLngDTO;
import com.carpool.backend.dto.OptimizeRequestDTO;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.auth.oauth2.AccessToken;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.client.RestClient;

import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.atLeast;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RouteOptimizationController.class)
@AutoConfigureMockMvc(addFilters = false)
class RouteOptimizationControllerWebMvcTest {

    private static final String GOOGLE_RESPONSE_JSON = """
            {
              "routes": [
                {
                  "vehicleIndex": 0,
                  "visits": [
                    {
                      "label": "pickup_student_1",
                      "shipmentLabel": "student_1",
                      "startTime": "2026-01-01T00:10:00Z"
                    },
                    {
                      "label": "dropoff_student_1",
                      "shipmentLabel": "student_1",
                      "startTime": "2026-01-01T00:25:00Z"
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
                      "label": "pickup_student_2",
                      "shipmentLabel": "student_2",
                      "startTime": "2026-01-01T00:12:00Z"
                    },
                    {
                      "label": "dropoff_student_2",
                      "shipmentLabel": "student_2",
                      "startTime": "2026-01-01T00:30:00Z"
                    }
                  ],
                  "metrics": {
                    "travelDuration": "1080s"
                  }
                }
              ]
            }
            """;

    private static final String GOOGLE_RESPONSE_WITH_UNKNOWN_DRIVER_JSON = """
            {
              "routes": [
                {
                  "vehicleIndex": 99,
                  "visits": [
                    {
                      "label": "pickup_student_1",
                      "shipmentLabel": "student_1",
                      "startTime": "2026-01-01T00:10:00Z"
                    }
                  ],
                  "metrics": {
                    "travelDuration": "300s"
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
                  "vehicleIndex": 0,
                  "visits": [],
                  "metrics": {
                    "travelDuration": "0s"
                  }
                }
              ]
            }
            """;

    private static final String GOOGLE_RESPONSE_SINGLE_ROUTE_JSON = """
            {
              "routes": [
                {
                  "vehicleIndex": 0,
                  "visits": [
                    {
                      "label": "pickup_student_1",
                      "shipmentLabel": "student_1",
                      "startTime": "2026-01-01T00:10:00Z"
                    },
                    {
                      "label": "dropoff_student_1",
                      "shipmentLabel": "student_1",
                      "startTime": "2026-01-01T00:25:00Z"
                    }
                  ],
                  "metrics": {
                    "travelDuration": "900s"
                  }
                }
              ]
            }
            """;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private RouteOptimizationController controller;

    private RestClient.RequestBodySpec requestBodySpec;
    private String googleResponseJson;

    @BeforeEach
    void setUp() {
        RestClient restClient = Mockito.mock(RestClient.class);
        RestClient.RequestBodyUriSpec requestBodyUriSpec = Mockito.mock(RestClient.RequestBodyUriSpec.class);
        requestBodySpec = Mockito.mock(RestClient.RequestBodySpec.class);
        RestClient.ResponseSpec responseSpec = Mockito.mock(RestClient.ResponseSpec.class);

        googleResponseJson = GOOGLE_RESPONSE_JSON;

        when(restClient.post()).thenReturn(requestBodyUriSpec);
        doReturn(requestBodySpec).when(requestBodyUriSpec).uri(anyString(), any(Object[].class));
        when(requestBodySpec.header(eq(HttpHeaders.AUTHORIZATION), anyString())).thenReturn(requestBodySpec);
        when(requestBodySpec.contentType(MediaType.APPLICATION_JSON)).thenReturn(requestBodySpec);
        when(requestBodySpec.body(any(Map.class))).thenReturn(requestBodySpec);
        when(requestBodySpec.retrieve()).thenReturn(responseSpec);
        when(responseSpec.body(String.class)).thenAnswer(invocation -> googleResponseJson);

        ReflectionTestUtils.setField(controller, "rest", restClient);
        ReflectionTestUtils.setField(controller, "projectId", "test-project-id");
        ReflectionTestUtils.setField(
                controller,
                "cachedToken",
                new AccessToken("fake-token", Date.from(Instant.now().plusSeconds(3600)))
        );
    }

    @SuppressWarnings("unchecked")
    @Test
    void optimize_shouldReturnTwoRoutePlans_andBuildExpectedGoogleBody() throws Exception {
        OptimizeRequestDTO request = buildRequest();

        mockMvc.perform(post("/api/optimize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0]").exists())
                .andExpect(jsonPath("$[1]").exists())
                .andExpect(jsonPath("$[2]").doesNotExist())
                .andExpect(jsonPath("$[0].driverId").value("d1"))
                .andExpect(jsonPath("$[1].driverId").value("d2"))
                .andExpect(jsonPath("$[0].driverHome.lat").value(43.0731))
                .andExpect(jsonPath("$[0].driverHome.lng").value(-89.4012))
                .andExpect(jsonPath("$[0].eventLocation.lat").value(43.0800))
                .andExpect(jsonPath("$[0].eventLocation.lng").value(-89.4000))
                .andExpect(jsonPath("$[0].timeline[0].type").value("pickup"))
                .andExpect(jsonPath("$[0].timeline[0].studentId").value("1"))
                .andExpect(jsonPath("$[0].timeline[0].location.lat").value(43.0750))
                .andExpect(jsonPath("$[0].timeline[0].location.lng").value(-89.4100))
                .andExpect(jsonPath("$[0].timeline[1].type").value("dropoff"))
                .andExpect(jsonPath("$[0].timeline[1].studentId").value("1"))
                .andExpect(jsonPath("$[0].timeline[1].location.lat").value(43.0800))
                .andExpect(jsonPath("$[0].timeline[1].location.lng").value(-89.4000))
                .andExpect(jsonPath("$[1].timeline[0].type").value("pickup"))
                .andExpect(jsonPath("$[1].timeline[0].studentId").value("2"))
                .andExpect(jsonPath("$[1].timeline[0].location.lat").value(43.0700))
                .andExpect(jsonPath("$[1].timeline[0].location.lng").value(-89.4200))
                .andExpect(jsonPath("$[1].timeline[1].type").value("dropoff"))
                .andExpect(jsonPath("$[1].timeline[1].studentId").value("2"))
                .andExpect(jsonPath("$[1].timeline[1].location.lat").value(43.0800))
                .andExpect(jsonPath("$[1].timeline[1].location.lng").value(-89.4000));

        ArgumentCaptor<Map<String, Object>> bodyCaptor = ArgumentCaptor.forClass(Map.class);
        verify(requestBodySpec).body(bodyCaptor.capture());

        Map<String, Object> outboundBody = bodyCaptor.getValue();
        Map<String, Object> model = (Map<String, Object>) outboundBody.get("model");
        List<Map<String, Object>> objectives = (List<Map<String, Object>>) model.get("objectives");
        List<Map<String, Object>> vehicles = (List<Map<String, Object>>) model.get("vehicles");
        List<Map<String, Object>> shipments = (List<Map<String, Object>>) model.get("shipments");

        assertEquals(1, objectives.size());
        assertEquals("MIN_TRAVEL_TIME", objectives.get(0).get("type"));

        assertEquals(request.drivers.size(), vehicles.size());
        assertEquals(request.students.size(), shipments.size());

        for (Map<String, Object> vehicle : vehicles) {
            Map<String, Object> loadLimits = (Map<String, Object>) vehicle.get("loadLimits");
            Map<String, Object> seats = (Map<String, Object>) loadLimits.get("seats");
            Object maxLoad = seats.get("maxLoad");
            assertTrue(maxLoad instanceof String);
        }

        for (Map<String, Object> shipment : shipments) {
            String studentId = ((String) shipment.get("name")).substring("students/".length());

            Map<String, Object> loadDemands = (Map<String, Object>) shipment.get("loadDemands");
            Map<String, Object> seatsDemand = (Map<String, Object>) loadDemands.get("seats");
            Object amount = seatsDemand.get("amount");
            List<Map<String, Object>> pickups = (List<Map<String, Object>>) shipment.get("pickups");
            List<Map<String, Object>> deliveries = (List<Map<String, Object>>) shipment.get("deliveries");

            assertTrue(amount instanceof String);
            assertEquals(1, pickups.size());
            assertEquals(1, deliveries.size());
            assertEquals("pickup_student_" + studentId, pickups.get(0).get("label"));
            assertEquals("dropoff_student_" + studentId, deliveries.get(0).get("label"));
        }
    }

    @Test
    void optimize_shouldReturnStableUnknownDriverId_whenVehicleMappingFails() throws Exception {
        googleResponseJson = GOOGLE_RESPONSE_WITH_UNKNOWN_DRIVER_JSON;
        OptimizeRequestDTO request = buildRequest();

        mockMvc.perform(post("/api/optimize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].driverId").value("unknown_driver_1"))
                .andExpect(jsonPath("$[0].driverId").isNotEmpty())
                .andExpect(jsonPath("$[0].timeline[0].type").value("pickup"));
    }

    @Test
    void optimize_shouldReturnEmptyList_whenRoutesArrayIsEmpty() throws Exception {
        googleResponseJson = GOOGLE_RESPONSE_EMPTY_ROUTES_JSON;
        OptimizeRequestDTO request = buildRequest();

        mockMvc.perform(post("/api/optimize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0]").doesNotExist());
    }

    @Test
    void optimize_shouldReturnPlanWithEmptyTimeline_whenRouteVisitsEmpty() throws Exception {
        googleResponseJson = GOOGLE_RESPONSE_ROUTE_WITH_EMPTY_VISITS_JSON;
        OptimizeRequestDTO request = buildRequest();

        mockMvc.perform(post("/api/optimize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].driverId").value("d1"))
                .andExpect(jsonPath("$[0].timeline").isArray())
                .andExpect(jsonPath("$[0].timeline[0]").doesNotExist());
    }

    @SuppressWarnings("unchecked")
    @Test
    void optimize_perVehicleMode_shouldRespectCapacity_andReturnMultipleRoutePlans() throws Exception {
        googleResponseJson = GOOGLE_RESPONSE_SINGLE_ROUTE_JSON;
        OptimizeRequestDTO request = buildPerVehicleRequestSatisfiable();

        mockMvc.perform(post("/api/optimize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0]").exists())
                .andExpect(jsonPath("$[1]").exists())
                .andExpect(jsonPath("$[0].timeline[0]").exists())
                .andExpect(jsonPath("$[1].timeline[0]").exists());

        ArgumentCaptor<Map<String, Object>> bodyCaptor = ArgumentCaptor.forClass(Map.class);
        verify(requestBodySpec, atLeast(2)).body(bodyCaptor.capture());

        List<Map<String, Object>> outboundBodies = bodyCaptor.getAllValues();
        for (Map<String, Object> outboundBody : outboundBodies) {
            Map<String, Object> model = (Map<String, Object>) outboundBody.get("model");
            List<Map<String, Object>> vehicles = (List<Map<String, Object>>) model.get("vehicles");
            List<Map<String, Object>> shipments = (List<Map<String, Object>>) model.get("shipments");

            assertEquals(1, vehicles.size());
            boolean hasStudents = !shipments.isEmpty();
            if (hasStudents) {
                assertTrue(shipments.size() <= 2);
            }
        }
    }

    @Test
    @SuppressWarnings("unchecked")
    void optimize_perVehicleMode_shouldReturnPartialPlans_whenTotalSeatsInsufficient() throws Exception {
        googleResponseJson = GOOGLE_RESPONSE_SINGLE_ROUTE_JSON;
        OptimizeRequestDTO request = buildPerVehicleRequestInsufficientSeats();

        mockMvc.perform(post("/api/optimize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0]").exists())
                .andExpect(jsonPath("$[1]").exists())
                .andExpect(jsonPath("$[2]").doesNotExist());

        ArgumentCaptor<Map<String, Object>> bodyCaptor = ArgumentCaptor.forClass(Map.class);
        verify(requestBodySpec, atLeast(2)).body(bodyCaptor.capture());

        List<Map<String, Object>> outboundBodies = bodyCaptor.getAllValues();
        for (Map<String, Object> outboundBody : outboundBodies) {
            Map<String, Object> model = (Map<String, Object>) outboundBody.get("model");
            List<Map<String, Object>> vehicles = (List<Map<String, Object>>) model.get("vehicles");
            List<Map<String, Object>> shipments = (List<Map<String, Object>>) model.get("shipments");

            assertEquals(1, vehicles.size());
            assertTrue(shipments.size() <= 1);
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

        request.students = List.of(s1, s2);
        request.globalStartTime = "2026-01-01T00:00:00Z";
        request.globalEndTime = "2026-01-01T06:00:00Z";
        return request;
    }

    private static OptimizeRequestDTO buildPerVehicleRequestSatisfiable() {
        OptimizeRequestDTO request = new OptimizeRequestDTO();
        request.mode = "PER_VEHICLE_MIN_TIME";

        request.event = new OptimizeRequestDTO.EventDTO();
        request.event.location = location(43.0800, -89.4000);

        OptimizeRequestDTO.DriverDTO d1 = new OptimizeRequestDTO.DriverDTO();
        d1.id = "d1";
        d1.home = location(43.0731, -89.4012);
        d1.seatCapacity = 2;

        OptimizeRequestDTO.DriverDTO d2 = new OptimizeRequestDTO.DriverDTO();
        d2.id = "d2";
        d2.home = location(43.0500, -89.5000);
        d2.seatCapacity = 2;

        request.drivers = List.of(d1, d2);

        OptimizeRequestDTO.StudentDTO s1 = new OptimizeRequestDTO.StudentDTO();
        s1.id = "1";
        s1.home = location(43.0750, -89.4100);

        OptimizeRequestDTO.StudentDTO s2 = new OptimizeRequestDTO.StudentDTO();
        s2.id = "2";
        s2.home = location(43.0700, -89.4200);

        OptimizeRequestDTO.StudentDTO s3 = new OptimizeRequestDTO.StudentDTO();
        s3.id = "3";
        s3.home = location(43.0600, -89.4300);

        OptimizeRequestDTO.StudentDTO s4 = new OptimizeRequestDTO.StudentDTO();
        s4.id = "4";
        s4.home = location(43.0620, -89.4320);

        request.students = List.of(s1, s2, s3, s4);
        request.globalStartTime = "2026-01-01T00:00:00Z";
        request.globalEndTime = "2026-01-01T06:00:00Z";
        return request;
    }

    private static OptimizeRequestDTO buildPerVehicleRequestInsufficientSeats() {
        OptimizeRequestDTO request = new OptimizeRequestDTO();
        request.mode = "PER_VEHICLE_MIN_TIME";

        request.event = new OptimizeRequestDTO.EventDTO();
        request.event.location = location(43.0800, -89.4000);

        OptimizeRequestDTO.DriverDTO d1 = new OptimizeRequestDTO.DriverDTO();
        d1.id = "d1";
        d1.home = location(43.0731, -89.4012);
        d1.seatCapacity = 1;

        OptimizeRequestDTO.DriverDTO d2 = new OptimizeRequestDTO.DriverDTO();
        d2.id = "d2";
        d2.home = location(43.0500, -89.5000);
        d2.seatCapacity = 1;

        request.drivers = List.of(d1, d2);

        OptimizeRequestDTO.StudentDTO s1 = new OptimizeRequestDTO.StudentDTO();
        s1.id = "1";
        s1.home = location(43.0750, -89.4100);

        OptimizeRequestDTO.StudentDTO s2 = new OptimizeRequestDTO.StudentDTO();
        s2.id = "2";
        s2.home = location(43.0700, -89.4200);

        OptimizeRequestDTO.StudentDTO s3 = new OptimizeRequestDTO.StudentDTO();
        s3.id = "3";
        s3.home = location(43.0600, -89.4300);

        request.students = List.of(s1, s2, s3);
        request.globalStartTime = "2026-01-01T00:00:00Z";
        request.globalEndTime = "2026-01-01T06:00:00Z";
        return request;
    }

    private static LatLngDTO location(double lat, double lng) {
        LatLngDTO loc = new LatLngDTO();
        loc.lat = lat;
        loc.lng = lng;
        return loc;
    }
}
