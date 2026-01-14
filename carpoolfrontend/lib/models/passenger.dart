class Passenger {
  final String id;
  final String name;
  final String addressText;
  final bool active;

  Passenger({
    required this.id,
    required this.name,
    required this.addressText,
    this.active = true,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: _asString(json['id']),
      name: _asString(json['name']),
      addressText: _asString(json['address'] ?? json['addressText']),
      active: _asBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 后端如果是自增 id，创建时通常不传；但这里保留兼容
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'name': name,
      'address': addressText,
    };
  }

  Passenger copyWith({
    String? id,
    String? name,
    String? addressText,
    bool? active,
  }) {
    return Passenger(
      id: id ?? this.id,
      name: name ?? this.name,
      addressText: addressText ?? this.addressText,
      active: active ?? this.active,
    );
  }
}

String _asString(dynamic v) => v?.toString() ?? '';

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return true;
}
