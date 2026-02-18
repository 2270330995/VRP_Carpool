package com.carpool.backend.controller;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class RouteOptimizationTimestampTest {

    @Test
    void normalizeUtcTimestamp_shouldRemoveMilliseconds() {
        String normalized = RouteOptimizationController.normalizeUtcTimestamp("2026-02-17T04:31:54.937Z");
        assertEquals("2026-02-17T04:31:54Z", normalized);
    }
}
