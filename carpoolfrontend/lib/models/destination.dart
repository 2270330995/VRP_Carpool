class Destination {
  final String id;
  final String name;
  final String addressText;
  final bool active;

  Destination({
    required this.id,
    required this.name,
    required this.addressText,
    this.active = true,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: _asString(json['id']),
      name: _asString(json['name']),
      addressText: _asString(json['address'] ?? json['addressText']),
      active: _asBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'name': name,
      'address': addressText,
    };
  }

  Destination copyWith({
    String? id,
    String? name,
    String? addressText,
    bool? active,
  }) {
    return Destination(
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
