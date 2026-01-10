class Destination {
  final String id;
  final String name;
  final String addressText;
  final double lat;
  final double lng;

  Destination({
    required this.id,
    required this.name,
    required this.addressText,
    required this.lat,
    required this.lng,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: _asString(json['id']),
      name: _asString(json['name']),
      addressText: _asString(json['address'] ?? json['addressText']),
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'name': name,
      'address': addressText,
      // 'lat': lat,
      // 'lng': lng,
    };
  }

  Destination copyWith({
    String? id,
    String? name,
    String? addressText,
    double? lat,
    double? lng,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      addressText: addressText ?? this.addressText,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

String _asString(dynamic v) => v?.toString() ?? '';

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
