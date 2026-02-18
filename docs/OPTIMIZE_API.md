# Optimize API

## Endpoint
- **Method**: `POST`
- **URL**: `/api/optimize`
- **Content-Type**: `application/json`
- **Response Type**: `application/json`

## Description
Computes multi-driver carpool routes using Google Route Optimization API.  
Each returned route is bound to one driver and includes a timeline of pickup/dropoff visits.

## Request Body

### Example
```json
{
  "event": {
    "location": {
      "lat": 43.0800,
      "lng": -89.4000
    }
  },
  "drivers": [
    {
      "id": "d1",
      "home": {
        "latitude": 43.0731,
        "longitude": -89.4012
      },
      "seatCapacity": 4
    },
    {
      "id": "d2",
      "home": {
        "lat": 43.0680,
        "lng": -89.3980
      },
      "seatCapacity": 3
    }
  ],
  "students": [
    {
      "id": "1",
      "home": {
        "lat": 43.0750,
        "lng": -89.4100
      }
    },
    {
      "id": "2",
      "home": {
        "lat": 43.0700,
        "lng": -89.4200
      }
    },
    {
      "id": "3",
      "home": {
        "lat": 43.0650,
        "lng": -89.4050
      }
    }
  ],
  "globalStartTime": "2026-01-01T00:00:00Z",
  "globalEndTime": "2026-01-01T06:00:00Z"
}
```

### Field Notes
- `event.location`: destination/event location where all students are dropped off.
- `drivers[].id`: driver identifier used for route binding in response.
- `drivers[].home`: driver start location.
- `drivers[].seatCapacity`: mapped to vehicle seat capacity.
- `students[].id`: student identifier used in labels and timeline parsing.
- `students[].home`: pickup location.
- `globalStartTime`, `globalEndTime`: optional optimization time window (RFC3339 UTC timestamp format recommended).

### Coordinate Aliases
`lat/lng` and `latitude/longitude` are both accepted in request JSON.

## Response Body

### Example
```json
[
  {
    "driverId": "d1",
    "timeline": [
      {
        "sequence": 0,
        "time": "2026-01-01T00:10:00Z",
        "type": "pickup",
        "studentId": "1",
        "shipmentLabel": "student_1",
        "visitLabel": "pickup_student_1"
      },
      {
        "sequence": 1,
        "time": "2026-01-01T00:27:00Z",
        "type": "dropoff",
        "studentId": "1",
        "shipmentLabel": "student_1",
        "visitLabel": "dropoff_student_1"
      }
    ],
    "metrics": {
      "travelDuration": "1020s"
    }
  },
  {
    "driverId": "d2",
    "timeline": [
      {
        "sequence": 0,
        "time": "2026-01-01T00:12:00Z",
        "type": "pickup",
        "studentId": "2",
        "shipmentLabel": "student_2",
        "visitLabel": "pickup_student_2"
      },
      {
        "sequence": 1,
        "time": "2026-01-01T00:30:00Z",
        "type": "dropoff",
        "studentId": "2",
        "shipmentLabel": "student_2",
        "visitLabel": "dropoff_student_2"
      }
    ],
    "metrics": {
      "travelDuration": "1080s"
    }
  }
]
```

## Response Field Explanation
- `driverId`: driver bound to this route.
  - Primary mapping: Google `route.vehicleIndex` -> request `drivers[vehicleIndex].id`.
  - Fallback mapping: by `vehicleName` / `vehicleLabel` when available.
- `timeline`: ordered list of visits for the route.
- `timeline[].sequence`: 0-based order in route.
- `timeline[].time`: visit start time from Google route response.
- `timeline[].type`:
  - `pickup` when `visitLabel` starts with `pickup_`
  - `dropoff` when `visitLabel` starts with `dropoff_`
  - `visit` otherwise
- `timeline[].studentId`: extracted from label by splitting on `_` and taking the last segment.
- `timeline[].shipmentLabel`: Google shipment label for traceability.
- `timeline[].visitLabel`: Google visit label for traceability.
- `metrics`: per-route metrics from Google response (`route.metrics`).

## Constraints and Assumptions
- Objective is fixed to `MIN_TRAVEL_TIME`.
- Each driver is modeled as one Google vehicle:
  - start = `driver.home`
  - end = `event.location`
  - capacity = `driver.seatCapacity`
- Each student is modeled as one shipment:
  - pickup = `student.home`
  - delivery = `event.location`
- Label protocol is required for timeline parsing compatibility:
  - pickup label: `pickup_student_{studentId}`
  - dropoff label: `dropoff_student_{studentId}`
- Request validation requires:
  - non-empty `drivers` and `students`
  - each driver has `id`, `home`, `seatCapacity > 0`
  - each student has `id`, `home`
  - event has `location`
  - all coordinates provide both latitude and longitude values
