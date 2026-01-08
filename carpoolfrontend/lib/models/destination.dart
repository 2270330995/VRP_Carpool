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
