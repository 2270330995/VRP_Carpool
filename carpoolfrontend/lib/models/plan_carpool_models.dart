import 'place_selection.dart';

class EventInput {
  EventInput({this.place});

  PlaceSelection? place;

  factory EventInput.fromJson(Map<String, dynamic> json) {
    final placeJson = json['place'];
    return EventInput(
      place: placeJson is Map<String, dynamic>
          ? PlaceSelection.fromJson(placeJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {'place': place?.toJson()};
}

class DriverInput {
  DriverInput({
    required this.id,
    required this.name,
    required this.seatCapacity,
    this.home,
  });

  String id;
  String name;
  int seatCapacity;
  PlaceSelection? home;

  factory DriverInput.fromJson(Map<String, dynamic> json) {
    final homeJson = json['home'];
    return DriverInput(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      seatCapacity: (json['seatCapacity'] as num?)?.toInt() ?? 4,
      home: homeJson is Map<String, dynamic>
          ? PlaceSelection.fromJson(homeJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'seatCapacity': seatCapacity,
    'home': home?.toJson(),
  };
}

class StudentInput {
  StudentInput({required this.id, required this.name, this.home});

  String id;
  String name;
  PlaceSelection? home;

  factory StudentInput.fromJson(Map<String, dynamic> json) {
    final homeJson = json['home'];
    return StudentInput(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      home: homeJson is Map<String, dynamic>
          ? PlaceSelection.fromJson(homeJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'home': home?.toJson(),
  };
}

class OptimizeTimelineEntry {
  OptimizeTimelineEntry({
    required this.sequence,
    required this.time,
    required this.type,
    required this.studentId,
    required this.shipmentLabel,
    required this.visitLabel,
    required this.location,
  });

  final int sequence;
  final String? time;
  final String? type;
  final String? studentId;
  final String? shipmentLabel;
  final String? visitLabel;
  final LatLngPoint? location;

  factory OptimizeTimelineEntry.fromJson(Map<String, dynamic> json) {
    return OptimizeTimelineEntry(
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      time: json['time'] as String?,
      type: json['type'] as String?,
      studentId: json['studentId'] as String?,
      shipmentLabel: json['shipmentLabel'] as String?,
      visitLabel: json['visitLabel'] as String?,
      location: json['location'] is Map<String, dynamic>
          ? LatLngPoint.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'time': time,
    'type': type,
    'studentId': studentId,
    'shipmentLabel': shipmentLabel,
    'visitLabel': visitLabel,
    'location': location?.toJson(),
  };
}

class OptimizeRoutePlan {
  OptimizeRoutePlan({
    required this.driverId,
    required this.driverHome,
    required this.eventLocation,
    required this.timeline,
    required this.metrics,
  });

  final String? driverId;
  final LatLngPoint? driverHome;
  final LatLngPoint? eventLocation;
  final List<OptimizeTimelineEntry> timeline;
  final Map<String, dynamic> metrics;

  factory OptimizeRoutePlan.fromJson(Map<String, dynamic> json) {
    return OptimizeRoutePlan(
      driverId: json['driverId'] as String?,
      driverHome: json['driverHome'] is Map<String, dynamic>
          ? LatLngPoint.fromJson(json['driverHome'] as Map<String, dynamic>)
          : null,
      eventLocation: json['eventLocation'] is Map<String, dynamic>
          ? LatLngPoint.fromJson(json['eventLocation'] as Map<String, dynamic>)
          : null,
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OptimizeTimelineEntry.fromJson)
          .toList(),
      metrics: (json['metrics'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'driverHome': driverHome?.toJson(),
    'eventLocation': eventLocation?.toJson(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'metrics': metrics,
  };
}
