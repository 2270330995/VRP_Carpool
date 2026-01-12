class Passenger {
  final String id;
  final String name;
  final String addressText;

  Passenger({
    required this.id,
    required this.name,
    required this.addressText,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: _asString(json['id']),
      name: _asString(json['name']),
      addressText: _asString(json['address'] ?? json['addressText']),
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
  }) {
    return Passenger(
      id: id ?? this.id,
      name: name ?? this.name,
      addressText: addressText ?? this.addressText,
    );
  }
}

String _asString(dynamic v) => v?.toString() ?? '';
