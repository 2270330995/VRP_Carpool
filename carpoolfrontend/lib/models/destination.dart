class Destination {
  final String id;
  final String name;
  final String addressText;

  Destination({
    required this.id,
    required this.name,
    required this.addressText,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: _asString(json['id']),
      name: _asString(json['name']),
      addressText: _asString(json['address'] ?? json['addressText']),
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
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      addressText: addressText ?? this.addressText,
    );
  }
}

String _asString(dynamic v) => v?.toString() ?? '';
