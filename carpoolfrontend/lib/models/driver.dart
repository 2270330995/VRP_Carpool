class Driver {
  final String id;
  final String name;
  final int seats;
  final String addressText;
  final double lat;
  final double lng;

  Driver({
    required this.id,
    required this.name,
    required this.seats,
    required this.addressText,
    required this.lat,
    required this.lng,
  });

  Driver copyWith({
    String? id,
    String? name,
    int? seats,
    String? addressText,
    double? lat,
    double? lng,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      seats: seats ?? this.seats,
      addressText: addressText ?? this.addressText,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}
