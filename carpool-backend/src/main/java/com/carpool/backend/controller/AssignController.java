package com.carpool.backend.controller;

import com.carpool.backend.dto.RunDetailDto;
import com.carpool.backend.entity.*;
import com.carpool.backend.repository.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ResponseStatusException;
import static org.springframework.http.HttpStatus.NOT_FOUND;
import static org.springframework.http.HttpStatus.BAD_REQUEST;


import java.util.*;

@RestController
@RequestMapping("/api/assign")
public class AssignController {

    private final DriverRepository driverRepository;
    private final PassengerRepository passengerRepository;
    private final AssignmentRunRepository runRepository;
    private final AssignmentRepository assignmentRepository;
    private final DestinationRepository destinationRepository;


    public AssignController(DriverRepository driverRepository,
                            PassengerRepository passengerRepository,
                            AssignmentRunRepository runRepository,
                            AssignmentRepository assignmentRepository,
                            DestinationRepository destinationRepository) {
        this.driverRepository = driverRepository;
        this.passengerRepository = passengerRepository;
        this.runRepository = runRepository;
        this.assignmentRepository = assignmentRepository;
        this.destinationRepository = destinationRepository;
    }


    // 1) 生成一次新的分配，并写入历史
    // POST /api/assign
    @PostMapping
    public Map<String, Object> assignAndSave(
            @RequestParam(value = "note", required = false) String note,
            @RequestParam(value = "destinationId", required = false) Long destinationId
    )
    {
        List<DriverEntity> drivers = driverRepository.findByActiveTrueOrActiveIsNull();
        List<PassengerEntity> passengers = passengerRepository.findByActiveTrueOrActiveIsNull();

        // 新建一次 run
        AssignmentRunEntity run = new AssignmentRunEntity();
        run.setNote(note);

        if (destinationId != null) {
            DestinationEntity dest = destinationRepository.findById(destinationId)
                    .orElseThrow(() -> new ResponseStatusException(
                            NOT_FOUND,
                            "Destination not found: " + destinationId
                    ));
            run.setDestination(dest);
        }

        run = runRepository.save(run);


        int pIdx = 0;
        int totalAssigned = 0;

        // 逐司机填满 seats
        for (DriverEntity d : drivers) {
            int capacity = d.getSeats() == null ? 0 : d.getSeats();
            int stopOrder = 1;

            while (pIdx < passengers.size() && stopOrder <= capacity) {
                PassengerEntity p = passengers.get(pIdx++);
                AssignmentEntity a = new AssignmentEntity(run, d, p, stopOrder);
                assignmentRepository.save(a);
                stopOrder++;
                totalAssigned++;
            }
        }

        int unassignedCount = passengers.size() - totalAssigned;

        return Map.of(
                "runId", run.getId(),
                "assignedCount", totalAssigned,
                "unassignedCount", unassignedCount
        );
    }

    // 2) 历史列表：所有 run（简单返回）
    // GET /api/assign/runs
    @GetMapping("/runs")
    public List<Map<String, Object>> listRuns() {
        List<AssignmentRunEntity> runs = runRepository.findAll();
        // 按时间倒序（简单做法：手动排序）
        runs.sort(Comparator.comparing(AssignmentRunEntity::getCreatedAt).reversed());

        List<Map<String, Object>> out = new ArrayList<>();
        for (AssignmentRunEntity r : runs) {
            out.add(Map.of(
                    "runId", r.getId(),
                    "createdAt", r.getCreatedAt(),
                    "note", r.getNote()
            ));
        }
        return out;
    }

    // 3) 最新一次 run 详情
    // GET /api/assign/runs/latest
    @GetMapping("/runs/latest")
    public ResponseEntity<?> latestRunDetail() {
        AssignmentRunEntity latest = runRepository.findTopByOrderByCreatedAtDesc();
        if (latest == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(buildRunDetail(latest.getId()));
    }

    // 4) 某一次 run 的详细分配
    // GET /api/assign/runs/{runId}
    @GetMapping("/runs/{runId}")
    public ResponseEntity<?> runDetail(@PathVariable Long runId) {
        if (!runRepository.existsById(runId)) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(buildRunDetail(runId));
    }

    // （可选）删除某次历史
    // DELETE /api/assign/runs/{runId}
    @DeleteMapping("/runs/{runId}")
    public ResponseEntity<?> deleteRun(@PathVariable Long runId) {
        if (!runRepository.existsById(runId)) return ResponseEntity.notFound().build();
        assignmentRepository.deleteByRunId(runId);
        runRepository.deleteById(runId);
        return ResponseEntity.noContent().build();
    }

    // 把 assignments 聚合成“每个司机的 stops”
    private RunDetailDto buildRunDetail(Long runId) {
        AssignmentRunEntity run = runRepository.findById(runId).orElseThrow();
        String destinationAddress = (run.getDestination() == null) ? null : run.getDestination().getAddress();

        List<AssignmentEntity> rows = assignmentRepository.findByRunIdOrderByDriverIdAscStopOrderAsc(runId);

        // driverId -> plan
        Map<Long, RunDetailDto.DriverPlan> planMap = new LinkedHashMap<>();
        Map<Long, String> driverAddressMap = new HashMap<>();

        for (AssignmentEntity a : rows) {
            DriverEntity d = a.getDriver();
            PassengerEntity p = a.getPassenger();

            RunDetailDto.DriverPlan plan = planMap.computeIfAbsent(d.getId(), k -> {
                RunDetailDto.DriverPlan dp = new RunDetailDto.DriverPlan();
                dp.googleMapsUrl = null;
                dp.driverId = d.getId();
                dp.driverName = d.getName();
                dp.seats = d.getSeats() == null ? 0 : d.getSeats();
                dp.stops = new ArrayList<>();
                return dp;
            });
            driverAddressMap.put(d.getId(), d.getAddress());

            RunDetailDto.Stop stop = new RunDetailDto.Stop();
            stop.order = a.getStopOrder();
            stop.passengerId = p.getId();
            stop.passengerName = p.getName();
            stop.passengerAddress = p.getAddress();

            plan.stops.add(stop);
        }

        // 统计哪些乘客已被分配
        Set<Long> assignedPassengerIds = new HashSet<>();
        for (AssignmentEntity a : rows) {
            assignedPassengerIds.add(a.getPassenger().getId());
        }

// 找出未分配的乘客（出现在 passengers 表里，但不在本次 assignments 里）
        List<PassengerEntity> allPassengers = passengerRepository.findByActiveTrueOrActiveIsNull();
        List<RunDetailDto.Stop> unassignedStops = new ArrayList<>();
        for (PassengerEntity p : allPassengers) {
            if (!assignedPassengerIds.contains(p.getId())) {
                RunDetailDto.Stop s = new RunDetailDto.Stop();
                s.order = 0; // 未分配，没有顺序
                s.passengerId = p.getId();
                s.passengerName = p.getName();
                s.passengerAddress = p.getAddress();
                unassignedStops.add(s);
            }
        }

        unassignedStops.sort(Comparator.comparing(s -> s.passengerName));

        RunDetailDto dto = new RunDetailDto();
        dto.runId = run.getId();
        dto.createdAt = run.getCreatedAt();
        if (destinationAddress != null) {
            for (RunDetailDto.DriverPlan plan : planMap.values()) {
                String origin = driverAddressMap.get(plan.driverId);
                if (origin == null || origin.isBlank()) continue;

                // waypoints：乘客地址按 stops 顺序
                List<String> waypointAddrs = new ArrayList<>();
                for (RunDetailDto.Stop s : plan.stops) {
                    if (s.passengerAddress != null && !s.passengerAddress.isBlank()) {
                        waypointAddrs.add(s.passengerAddress);
                    }
                }

                plan.googleMapsUrl = buildGoogleMapsUrl(origin, destinationAddress, waypointAddrs);
            }
        }


        dto.plans = new ArrayList<>(planMap.values());

        // 未分配
        dto.unassigned = unassignedStops;
        dto.unassignedCount = unassignedStops.size();

        return dto;

    }

    private String buildGoogleMapsUrl(String origin, String destination, List<String> waypoints) {
        // Google Maps URL: https://www.google.com/maps/dir/?api=1&origin=...&destination=...&waypoints=a|b|c
        StringBuilder sb = new StringBuilder("https://www.google.com/maps/dir/?api=1");
        sb.append("&origin=").append(urlEncode(origin));
        sb.append("&destination=").append(urlEncode(destination));
        if (waypoints != null && !waypoints.isEmpty()) {
            sb.append("&waypoints=");
            for (int i = 0; i < waypoints.size(); i++) {
                if (i > 0) sb.append("|");
                sb.append(urlEncode(waypoints.get(i)));
            }
        }
        return sb.toString();
    }

    private String urlEncode(String s) {
        try {
            return java.net.URLEncoder.encode(s, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            return s;
        }
    }

    @GetMapping("/runs/{runId}/drivers/{driverId}/navigate")
    public ResponseEntity<?> driverNavigate(@PathVariable Long runId, @PathVariable Long driverId) {
        AssignmentRunEntity run = runRepository.findById(runId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Run not found: " + runId));

        DestinationEntity destination = run.getDestination();
        if (destination == null || destination.getAddress() == null || destination.getAddress().isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Run has no destination address");
        }

        DriverEntity driver = driverRepository.findById(driverId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Driver not found: " + driverId));

        if (driver.getAddress() == null || driver.getAddress().isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Driver has no address");
        }

        List<AssignmentEntity> rows =
                assignmentRepository.findByRunIdAndDriverIdOrderByStopOrderAsc(runId, driverId);

        List<String> waypoints = new ArrayList<>();
        for (AssignmentEntity a : rows) {
            PassengerEntity p = a.getPassenger();
            if (p != null && p.getAddress() != null && !p.getAddress().isBlank()) {
                waypoints.add(p.getAddress());
            }
        }

        String url = buildGoogleMapsUrl(driver.getAddress(), destination.getAddress(), waypoints);

        return ResponseEntity.ok(Map.of(
                "runId", runId,
                "driverId", driverId,
                "driverName", driver.getName(),
                "destinationAddress", destination.getAddress(),
                "url", url
        ));
    }

}
