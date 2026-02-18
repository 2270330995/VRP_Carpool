class LatLngPoint {
  LatLngPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory LatLngPoint.fromJson(Map<String, dynamic> json) {
    final latValue = json['lat'] ?? json['latitude'];
    final lngValue = json['lng'] ?? json['longitude'];
    return LatLngPoint(
      lat: (latValue as num).toDouble(),
      lng: (lngValue as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  String toCommaPair() => '$lat,$lng';
}

class PlaceSelection {
  PlaceSelection({
    required this.placeId,
    required this.description,
    required this.location,
  });

  final String placeId;
  final String description;
  final LatLngPoint location;

  factory PlaceSelection.fromJson(Map<String, dynamic> json) {
    return PlaceSelection(
      placeId: (json['placeId'] ?? json['place_id'] ?? '').toString(),
      description: (json['description'] ?? json['formatted_address'] ?? '')
          .toString(),
      location: LatLngPoint.fromJson(
        (json['location'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{'lat': 0.0, 'lng': 0.0},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'placeId': placeId,
    'description': description,
    'location': location.toJson(),
  };
}

class PlacePrediction {
  PlacePrediction({required this.placeId, required this.description});

  final String placeId;
  final String description;
}
