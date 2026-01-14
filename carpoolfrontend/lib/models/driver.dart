class Driver {
  final String id;
  final String name;
  final int seats;
  final String addressText;
  final String? carModel; // 兼容后端字段（如果有）
  final bool active;

  Driver({
    required this.id,
    required this.name,
    required this.seats,
    required this.addressText,
    this.carModel,
    this.active = true,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: _asString(json['id']),
      name: _asString(json['name']),
      seats: _asInt(json['seats']),
      addressText: _asString(json['address'] ?? json['addressText']),
      carModel: json['carModel']?.toString(),
      active: _asBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'name': name,
      'seats': seats,
      'address': addressText,
      if (carModel != null && carModel!.trim().isNotEmpty) 'carModel': carModel,
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    int? seats,
    String? addressText,
    String? carModel,
    bool? active,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      addressText: addressText ?? this.addressText,
      carModel: carModel ?? this.carModel,
      active: active ?? this.active,
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

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return true;
}
