// ============================================================
// weather_detail_model.dart
// ============================================================

class DailyForecastModel {
  /// Date in yyyy-MM-dd format
  final String dateTxt;

  /// Minimum actual forecasted temperature for the entire day
  final double minTemp;

  /// Maximum actual forecasted temperature for the entire day
  final double maxTemp;

  /// Main weather condition
  final String condition;

  /// Weather condition description
  final String description;

  /// Icon compatible with the previous OpenWeather structure
  final String icon;

  /// Wind speed for that day
  /// Unit: km/h
  final double windSpeed;

  DailyForecastModel({
    required this.dateTxt,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.description,
    required this.icon,
    this.windSpeed = 0.0,
  });

  factory DailyForecastModel.fromJson(Map<String, dynamic> json) {
    return DailyForecastModel(
      dateTxt: json['date_txt']?.toString() ?? '',

      minTemp: _toDouble(json['min_temp']) ?? 0.0,

      maxTemp: _toDouble(json['max_temp']) ?? 0.0,

      condition: json['condition']?.toString() ?? 'Clear',

      description: json['description']?.toString() ?? '',

      icon: json['icon']?.toString() ?? '',

      windSpeed: _toDouble(json['wind_speed']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_txt': dateTxt,
      'min_temp': minTemp,
      'max_temp': maxTemp,
      'condition': condition,
      'description': description,
      'icon': icon,
      'wind_speed': windSpeed,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}

// ============================================================
// WeatherDetailModel
// ============================================================

class WeatherDetailModel {
  /// Display city name.
  ///
  /// This remains the main city name used by the existing app.
  final String cityName;

  /// Persian city name.
  ///
  /// Example:
  /// تهران
  final String? cityNameFa;

  /// English city name.
  ///
  /// Example:
  /// Tehran
  final String? cityNameEn;

  /// Language used by the user when searching/selecting the city.
  ///
  /// 'fa' = Persian
  /// 'en' = English
  ///
  /// This allows the app to keep the selected search language
  /// when displaying the city on the main weather page.
  final String? searchLanguage;

  /// Country
  final String? country;

  /// Province / State
  final String? state;

  /// Coordinates
  final double latitude;
  final double longitude;

  /// Current weather
  final double temp;
  final double feelsLike;
  final int pressure;
  final int humidity;

  /// Wind speed
  /// Unit: km/h
  final double windSpeed;

  /// Wind direction in degrees
  final int windDeg;

  /// Current UV index
  final double uvIndex;

  final String weatherMain;
  final String weatherDescription;
  final String weatherIcon;

  /// Sunrise time
  /// Unix timestamp in seconds
  final int sunrise;

  /// Sunset time
  /// Unix timestamp in seconds
  final int sunset;

  /// Tomorrow's sunrise time
  /// Unix timestamp in seconds
  final int nextSunrise;

  /// Time difference of the location relative to UTC
  /// In seconds
  final int timezone;

  /// Daily forecast
  final List<DailyForecastModel> forecast;

  WeatherDetailModel({
    required this.cityName,
    this.cityNameFa,
    this.cityNameEn,
    this.searchLanguage,
    this.country,
    this.state,
    required this.latitude,
    required this.longitude,
    required this.temp,
    required this.feelsLike,
    required this.pressure,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.uvIndex,
    required this.weatherMain,
    required this.weatherDescription,
    required this.weatherIcon,
    this.sunrise = 0,
    this.sunset = 0,
    this.nextSunrise = 0,
    this.timezone = 0,
    this.forecast = const [],
  });

  // ==========================================================
  // Current Weather API
  // ==========================================================

  factory WeatherDetailModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] is Map
        ? Map<String, dynamic>.from(json['main'])
        : <String, dynamic>{};

    final wind = json['wind'] is Map
        ? Map<String, dynamic>.from(json['wind'])
        : <String, dynamic>{};

    final sys = json['sys'] is Map
        ? Map<String, dynamic>.from(json['sys'])
        : <String, dynamic>{};

    final coord = json['coord'] is Map
        ? Map<String, dynamic>.from(json['coord'])
        : <String, dynamic>{};

    Map<String, dynamic> weatherData = {};

    if (json['weather'] is List &&
        (json['weather'] as List).isNotEmpty &&
        json['weather'][0] is Map) {
      weatherData = Map<String, dynamic>.from(json['weather'][0]);
    }

    return WeatherDetailModel(
      cityName: json['name']?.toString() ?? '',

      cityNameFa: json['name_fa']?.toString(),

      cityNameEn: json['name_en']?.toString(),

      searchLanguage: json['search_language']?.toString(),

      country: sys['country']?.toString(),

      state: json['state']?.toString(),

      latitude: _toDouble(coord['lat']) ?? 0.0,

      longitude: _toDouble(coord['lon']) ?? 0.0,

      temp: _toDouble(main['temp']) ?? 0.0,

      feelsLike: _toDouble(main['feels_like']) ?? 0.0,

      pressure: _toInt(main['pressure']) ?? 0,

      humidity: _toInt(main['humidity']) ?? 0,

      windSpeed: _toDouble(wind['speed']) ?? 0.0,

      windDeg: _toInt(wind['deg']) ?? 0,

      // Repository will later set the real Open-Meteo UV
      // using copyWith on the model.
      uvIndex: 0.0,

      weatherMain: weatherData['main']?.toString() ?? '',

      weatherDescription: weatherData['description']?.toString() ?? '',

      weatherIcon: weatherData['icon']?.toString() ?? '',

      sunrise: _toInt(sys['sunrise']) ?? 0,

      sunset: _toInt(sys['sunset']) ?? 0,

      nextSunrise: 0,

      timezone: _toInt(json['timezone']) ?? 0,

      forecast: const [],
    );
  }

  // ==========================================================
  // Hive Cache
  // ==========================================================

  factory WeatherDetailModel.fromCacheJson(Map<String, dynamic> json) {
    final rawForecast = json['forecast'];

    List<DailyForecastModel> parsedForecast = [];

    if (rawForecast is List) {
      parsedForecast = rawForecast
          .whereType<Map>()
          .map(
            (item) =>
                DailyForecastModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return WeatherDetailModel(
      cityName: json['city_name']?.toString() ?? '',

      cityNameFa: json['city_name_fa']?.toString(),

      cityNameEn: json['city_name_en']?.toString(),

      searchLanguage: json['search_language']?.toString(),

      country: json['country']?.toString(),

      state: json['state']?.toString(),

      latitude: _toDouble(json['latitude']) ?? 0.0,

      longitude: _toDouble(json['longitude']) ?? 0.0,

      temp: _toDouble(json['temp']) ?? 0.0,

      feelsLike: _toDouble(json['feels_like']) ?? 0.0,

      pressure: _toInt(json['pressure']) ?? 0,

      humidity: _toInt(json['humidity']) ?? 0,

      windSpeed: _toDouble(json['wind_speed']) ?? 0.0,

      windDeg: _toInt(json['wind_deg']) ?? 0,

      uvIndex: _toDouble(json['uv_index']) ?? 0.0,

      weatherMain: json['weather_main']?.toString() ?? '',

      weatherDescription: json['weather_description']?.toString() ?? '',

      weatherIcon: json['weather_icon']?.toString() ?? '',

      sunrise: _toInt(json['sunrise']) ?? 0,

      sunset: _toInt(json['sunset']) ?? 0,

      nextSunrise: _toInt(json['next_sunrise']) ?? 0,

      timezone: _toInt(json['timezone']) ?? 0,

      forecast: parsedForecast,
    );
  }

  // ==========================================================
  // Hive JSON
  // ==========================================================

  Map<String, dynamic> toJson() {
    return {
      'city_name': cityName,

      'city_name_fa': cityNameFa,

      'city_name_en': cityNameEn,

      'search_language': searchLanguage,

      'country': country,

      'state': state,

      'latitude': latitude,
      'longitude': longitude,

      'temp': temp,
      'feels_like': feelsLike,
      'pressure': pressure,
      'humidity': humidity,

      'wind_speed': windSpeed,
      'wind_deg': windDeg,

      'uv_index': uvIndex,

      'weather_main': weatherMain,
      'weather_description': weatherDescription,
      'weather_icon': weatherIcon,

      'sunrise': sunrise,
      'sunset': sunset,
      'next_sunrise': nextSunrise,
      'timezone': timezone,

      'forecast': forecast.map((e) => e.toJson()).toList(),
    };
  }

  // ==========================================================
  // copyWith
  // ==========================================================

  WeatherDetailModel copyWith({
    String? cityName,
    String? cityNameFa,
    String? cityNameEn,
    String? searchLanguage,
    String? country,
    String? state,
    double? latitude,
    double? longitude,
    double? temp,
    double? feelsLike,
    int? pressure,
    int? humidity,
    double? windSpeed,
    int? windDeg,
    double? uvIndex,
    String? weatherMain,
    String? weatherDescription,
    String? weatherIcon,
    int? sunrise,
    int? sunset,
    int? nextSunrise,
    int? timezone,
    List<DailyForecastModel>? forecast,
  }) {
    return WeatherDetailModel(
      cityName: cityName ?? this.cityName,

      cityNameFa: cityNameFa ?? this.cityNameFa,

      cityNameEn: cityNameEn ?? this.cityNameEn,

      searchLanguage: searchLanguage ?? this.searchLanguage,

      country: country ?? this.country,

      state: state ?? this.state,

      latitude: latitude ?? this.latitude,

      longitude: longitude ?? this.longitude,

      temp: temp ?? this.temp,

      feelsLike: feelsLike ?? this.feelsLike,

      pressure: pressure ?? this.pressure,

      humidity: humidity ?? this.humidity,

      windSpeed: windSpeed ?? this.windSpeed,

      windDeg: windDeg ?? this.windDeg,

      uvIndex: uvIndex ?? this.uvIndex,

      weatherMain: weatherMain ?? this.weatherMain,

      weatherDescription: weatherDescription ?? this.weatherDescription,

      weatherIcon: weatherIcon ?? this.weatherIcon,

      sunrise: sunrise ?? this.sunrise,

      sunset: sunset ?? this.sunset,

      nextSunrise: nextSunrise ?? this.nextSunrise,

      timezone: timezone ?? this.timezone,

      forecast: forecast ?? this.forecast,
    );
  }

  WeatherDetailModel copyWithForecast(List<DailyForecastModel> newForecast) {
    return copyWith(forecast: newForecast);
  }

  // ==========================================================
  // Full Location Name
  // ==========================================================

  String get fullLocationName {
    final parts = <String>[];

    if (cityName.isNotEmpty) {
      parts.add(cityName);
    }

    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }

    if (country != null && country!.isNotEmpty) {
      parts.add(country!);
    }

    return parts.join(', ');
  }

  // ==========================================================
  // Safe Number Parsers
  // ==========================================================

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}

// ============================================================
// CityGeoModel
// ============================================================

class CityGeoModel {
  final String name;

  final String? nameFa;

  final String? nameEn;

  final String? searchLanguage;

  final double lat;
  final double lon;

  final String? country;
  final String? state;

  CityGeoModel({
    required this.name,
    this.nameFa,
    this.nameEn,
    this.searchLanguage,
    required this.lat,
    required this.lon,
    this.country,
    this.state,
  });

  factory CityGeoModel.fromJson(Map<String, dynamic> json) {
    return CityGeoModel(
      name: json['name']?.toString() ?? '',

      nameFa: json['nameFa']?.toString(),

      nameEn: json['nameEn']?.toString(),

      searchLanguage: json['searchLanguage']?.toString(),

      lat: _toDouble(json['lat']) ?? 0.0,

      lon: _toDouble(json['lon']) ?? 0.0,

      country: json['country']?.toString(),

      state: json['state']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,

      'nameFa': nameFa,

      'nameEn': nameEn,

      'searchLanguage': searchLanguage,

      'lat': lat,

      'lon': lon,

      'country': country,

      'state': state,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
