class CityGeoModel {
  final String name;
  final double lat;
  final double lon;
  final String? country;
  final String? state;

  CityGeoModel({
    required this.name,
    required this.lat,
    required this.lon,
    this.country,
    this.state,
  });

  factory CityGeoModel.fromJson(Map<String, dynamic> json) {
    return CityGeoModel(
      name: json['name']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      country: json['country']?.toString(),
      state: json['state']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lon': lon,
      'country': country,
      'state': state,
    };
  }
}
