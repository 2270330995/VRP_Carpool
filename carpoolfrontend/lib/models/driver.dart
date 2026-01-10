class Driver {
  final String id;
  final String name;
  final int seats;
  final String addressText;
  final double lat;
  final double lng;
  final String? carModel; // 兼容后端字段（如果有）

  Driver({
    required this.id,
    required this.name,
    required this.seats,
    required this.addressText,
    required this.lat,
    required this.lng,
    this.carModel,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: _asString(json['id']),
      name: _asString(json['name']),
      seats: _asInt(json['seats']),
      addressText: _asString(json['address'] ?? json['addressText']),
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
      carModel: json['carModel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'name': name,
      'seats': seats,
      'address': addressText,
      if (carModel != null && carModel!.trim().isNotEmpty) 'carModel': carModel,
      // 'lat': lat,
      // 'lng': lng,
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    int? seats,
    String? addressText,
    double? lat,
    double? lng,
    String? carModel,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      addressText: addressText ?? this.addressText,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      carModel: carModel ?? this.carModel,
    );
  }
}

String _asString(dynamic v) => v?.toString() ?? '';

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
