import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/weather_detail_model.dart';

class WeatherRepository {
  final Dio _dio = Dio();

  // ============================================================
  // Open-Meteo URLs
  // ============================================================

  static const String _openMeteoUrl = 'https://api.open-meteo.com/v1/forecast';

  // ============================================================
  // Nominatim URLs
  // ============================================================

  static const String _nominatimSearchUrl =
      'https://nominatim.openstreetmap.org/search';

  static const String _reverseGeocodingUrl =
      'https://nominatim.openstreetmap.org/reverse';

  // ============================================================
  // Get complete weather information
  // ============================================================

  Future<WeatherDetailModel?> getWeatherDetails(
    double lat,
    double lon, {
    bool reverseGeocode = true,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('🌤️ GET WEATHER DETAILS - OPEN METEO');
      debugPrint('📍 Latitude: $lat');
      debugPrint('📍 Longitude: $lon');
      debugPrint('📍 Reverse Geocoding: $reverseGeocode');
      debugPrint('========================================');

      final response = await _dio.get(
        _openMeteoUrl,
        queryParameters: {
          'latitude': lat,
          'longitude': lon,

          // ====================================================
          // Current
          // ====================================================
          'current': [
            'temperature_2m',
            'relative_humidity_2m',
            'apparent_temperature',
            'pressure_msl',
            'wind_speed_10m',
            'wind_direction_10m',
            'weather_code',
            'uv_index',
            'is_day',
          ].join(','),

          // ====================================================
          // Hourly
          // ====================================================
          'hourly': [
            'temperature_2m',
            'relative_humidity_2m',
            'apparent_temperature',
            'pressure_msl',
            'wind_speed_10m',
            'wind_direction_10m',
            'weather_code',
            'uv_index',
          ].join(','),

          // ====================================================
          // Daily
          // ====================================================
          'daily': [
            'weather_code',
            'temperature_2m_max',
            'temperature_2m_min',
            'apparent_temperature_max',
            'apparent_temperature_min',
            'precipitation_sum',
            'precipitation_probability_max',
            'uv_index_max',
            'sunrise',
            'sunset',
            'wind_speed_10m_max',
            'wind_direction_10m_dominant',
          ].join(','),

          // ====================================================
          // Forecast
          // ====================================================
          'forecast_days': 7,

          // Local time of the location
          'timezone': 'auto',

          // ====================================================
          // Temperature unit
          // ====================================================
          'temperature_unit': 'celsius',

          // ====================================================
          // Wind speed
          // ====================================================
          'wind_speed_unit': 'kmh',

          // ====================================================
          // Precipitation unit
          // ====================================================
          'precipitation_unit': 'mm',
        },
      );

      if (response.statusCode != 200 || response.data is! Map) {
        debugPrint('❌ Open-Meteo API failed: ${response.statusCode}');

        return null;
      }

      debugPrint('✅ Open-Meteo API: 200');

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data,
      );

      // --------------------------------------------------------
      // Current
      // --------------------------------------------------------

      final Map<String, dynamic> currentData = data['current'] is Map
          ? Map<String, dynamic>.from(data['current'])
          : {};

      // --------------------------------------------------------
      // Daily
      // --------------------------------------------------------

      final Map<String, dynamic> dailyData = data['daily'] is Map
          ? Map<String, dynamic>.from(data['daily'])
          : {};

      final int utcOffsetSeconds = _toInt(data['utc_offset_seconds']) ?? 0;

      final List<dynamic> sunriseList = dailyData['sunrise'] is List
          ? List<dynamic>.from(dailyData['sunrise'])
          : [];

      final List<dynamic> sunsetList = dailyData['sunset'] is List
          ? List<dynamic>.from(dailyData['sunset'])
          : [];

      // --------------------------------------------------------
      // Today's sunrise
      // --------------------------------------------------------

      final int sunrise = sunriseList.isNotEmpty
          ? _parseOpenMeteoTimeToUnix(
              sunriseList.first?.toString(),
              utcOffsetSeconds,
            )
          : 0;

      // --------------------------------------------------------
      // Today's sunset
      // --------------------------------------------------------

      final int sunset = sunsetList.isNotEmpty
          ? _parseOpenMeteoTimeToUnix(
              sunsetList.first?.toString(),
              utcOffsetSeconds,
            )
          : 0;

      // --------------------------------------------------------
      // Tomorrow's sunrise
      // --------------------------------------------------------

      final int nextSunrise = sunriseList.length > 1
          ? _parseOpenMeteoTimeToUnix(
              sunriseList[1]?.toString(),
              utcOffsetSeconds,
            )
          : 0;

      debugPrint('🌅 Sunrise: $sunrise');
      debugPrint('🌇 Sunset: $sunset');
      debugPrint('🌅 Sunrise Tomorrow: $nextSunrise');
      debugPrint('🌍 UTC Offset: $utcOffsetSeconds seconds');

      // --------------------------------------------------------
      // Weather Code
      // --------------------------------------------------------

      final int? weatherCode = _toInt(currentData['weather_code']);

      if (weatherCode == null) {
        debugPrint('⚠️ Current weather_code is missing or invalid.');
      } else {
        debugPrint('🌤️ Open-Meteo weather_code: $weatherCode');
      }

      // --------------------------------------------------------
      // Current Weather Values
      // --------------------------------------------------------

      final double temp = _toDouble(currentData['temperature_2m']) ?? 0.0;

      final double feelsLike =
          _toDouble(currentData['apparent_temperature']) ?? temp;

      final double humidity =
          _toDouble(currentData['relative_humidity_2m']) ?? 0.0;

      final double pressure = _toDouble(currentData['pressure_msl']) ?? 0.0;

      // ========================================================
      // Current Wind
      // ========================================================

      final double windSpeed = _toDouble(currentData['wind_speed_10m']) ?? 0.0;

      final double windDeg =
          _toDouble(currentData['wind_direction_10m']) ?? 0.0;

      debugPrint(
        '💨 Current Wind: '
        '${windSpeed.toStringAsFixed(1)} km/h',
      );

      debugPrint(
        '🧭 Wind Direction: '
        '${windDeg.toStringAsFixed(0)}°',
      );

      // --------------------------------------------------------
      // Weather Condition
      // --------------------------------------------------------

      final String weatherMain = _weatherCodeToMain(weatherCode);

      final String weatherDescription = _weatherCodeToDescription(weatherCode);

      final String weatherIcon = _weatherCodeToIcon(
        weatherCode,
        currentData['is_day'],
      );

      debugPrint('🌤️ Weather Main: $weatherMain');

      debugPrint(
        '📝 Weather Description: '
        '$weatherDescription',
      );

      debugPrint('🖼️ Weather Icon: $weatherIcon');

      // --------------------------------------------------------
      // Build Map compatible with WeatherDetailModel
      // --------------------------------------------------------

      final Map<String, dynamic> normalizedCurrentData = {
        'name': '',
        'main': {
          'temp': temp,
          'feels_like': feelsLike,
          'pressure': pressure,
          'humidity': humidity,
        },
        'wind': {'speed': windSpeed, 'deg': windDeg},
        'weather': [
          {
            'main': weatherMain,
            'description': weatherDescription,
            'icon': weatherIcon,
          },
        ],
        'coord': {'lat': lat, 'lon': lon},
        'sys': {'sunrise': sunrise, 'sunset': sunset},
        'timezone': utcOffsetSeconds,
      };

      WeatherDetailModel weatherModel = WeatherDetailModel.fromJson(
        normalizedCurrentData,
      );

      // --------------------------------------------------------
      // Store tomorrow's sunrise
      // --------------------------------------------------------

      weatherModel = weatherModel.copyWith(nextSunrise: nextSunrise);

      // --------------------------------------------------------
      // Reverse Geocoding
      //
      // IMPORTANT:
      // When searching multiple cities, this can be disabled.
      // The search result already contains name/country/state.
      // This prevents multiple unnecessary Nominatim requests.
      // --------------------------------------------------------

      if (reverseGeocode) {
        try {
          final location = await _getLocationFromCoordinates(lat, lon);

          if (location != null) {
            final String? cityName = location['name']?.toString();

            final String? cityNameFa = location['nameFa']?.toString();

            final String? cityNameEn = location['nameEn']?.toString();

            final String? state = location['state']?.toString();

            final String? country = location['country']?.toString();

            weatherModel = weatherModel.copyWith(
              cityName: cityName,
              cityNameFa: cityNameFa,
              cityNameEn: cityNameEn,
              state: state,
              country: country,
            );

            debugPrint(
              '📍 Reverse Geocoding Location: '
              '${cityName ?? ''} | '
              '${state ?? ''} | '
              '${country ?? ''}',
            );

            debugPrint(
              '🇮🇷 Persian City Name: '
              '${cityNameFa ?? ''}',
            );

            debugPrint(
              '🇬🇧 English City Name: '
              '${cityNameEn ?? ''}',
            );
          } else {
            debugPrint('⚠️ Reverse Geocoding returned no location.');
          }
        } catch (e) {
          debugPrint('⚠️ Location lookup failed: $e');
        }
      } else {
        debugPrint('⏭️ Reverse Geocoding skipped.');
      }

      // --------------------------------------------------------
      // Forecast
      // --------------------------------------------------------

      try {
        final List<DailyForecastModel> dailyForecasts =
            _buildDailyForecastsFromOpenMeteo(data);

        weatherModel = weatherModel.copyWithForecast(dailyForecasts);

        debugPrint(
          '🌤️ Forecast count: '
          '${dailyForecasts.length}',
        );
      } catch (e, stackTrace) {
        debugPrint('⚠️ Forecast parsing failed: $e');

        debugPrintStack(stackTrace: stackTrace);
      }

      // --------------------------------------------------------
      // UV
      // --------------------------------------------------------

      final double? rawUvIndex = _getCurrentUvFromOpenMeteo(data);

      final double? uvIndex = rawUvIndex?.roundToDouble();

      debugPrint('========================================');

      if (uvIndex != null) {
        debugPrint(
          '🌞 FINAL UV INDEX: '
          '${uvIndex.toInt()}',
        );
      } else {
        debugPrint('🌞 FINAL UV INDEX: null');
      }

      debugPrint('========================================');

      if (uvIndex != null) {
        weatherModel = weatherModel.copyWith(uvIndex: uvIndex);

        debugPrint(
          '✅ UV ASSIGNED TO MODEL: '
          '${weatherModel.uvIndex.toInt()}',
        );
      } else {
        debugPrint('❌ UV VALUE NOT FOUND');
      }

      // --------------------------------------------------------
      // Final result
      // --------------------------------------------------------

      debugPrint('========================================');

      debugPrint('🌤️ WEATHER RESULT');

      debugPrint('City: ${weatherModel.cityName}');

      debugPrint('City FA: ${weatherModel.cityNameFa}');

      debugPrint('City EN: ${weatherModel.cityNameEn}');

      debugPrint('Search Language: ${weatherModel.searchLanguage}');

      debugPrint('State: ${weatherModel.state}');

      debugPrint('Country: ${weatherModel.country}');

      debugPrint('Temp: ${weatherModel.temp}');

      debugPrint('Humidity: ${weatherModel.humidity}');

      debugPrint('Pressure: ${weatherModel.pressure}');

      debugPrint(
        'Wind: '
        '${weatherModel.windSpeed.toStringAsFixed(1)} km/h',
      );

      debugPrint(
        'Wind Direction: '
        '${weatherModel.windDeg.toStringAsFixed(0)}°',
      );

      debugPrint('UV: ${weatherModel.uvIndex.toInt()}');

      debugPrint('Sunrise: ${weatherModel.sunrise}');

      debugPrint('Sunset: ${weatherModel.sunset}');

      debugPrint('Next Sunrise: ${weatherModel.nextSunrise}');

      debugPrint('Timezone: ${weatherModel.timezone}');

      debugPrint('Forecast: ${weatherModel.forecast.length}');

      debugPrint('========================================');

      return weatherModel;
    } on DioException catch (e, stackTrace) {
      debugPrint('========================================');

      debugPrint('❌ OPEN-METEO DIO ERROR');

      debugPrint('❌ STATUS: ${e.response?.statusCode}');

      debugPrint('❌ DATA: ${e.response?.data}');

      debugPrint('❌ MESSAGE: ${e.message}');

      debugPrint('========================================');

      debugPrintStack(stackTrace: stackTrace);

      return null;
    } catch (e, stackTrace) {
      debugPrint('========================================');

      debugPrint('❌ WEATHER REPOSITORY ERROR');

      debugPrint('❌ $e');

      debugPrint('========================================');

      debugPrintStack(stackTrace: stackTrace);

      return null;
    }
  }

  // ============================================================
  // Convert Open-Meteo time to Unix Timestamp
  // ============================================================

  int _parseOpenMeteoTimeToUnix(String? value, int utcOffsetSeconds) {
    if (value == null || value.isEmpty) {
      return 0;
    }

    try {
      final parsed = DateTime.parse(value);

      final utcLike = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      );

      return (utcLike.millisecondsSinceEpoch ~/ 1000) - utcOffsetSeconds;
    } catch (e) {
      debugPrint('❌ Open-Meteo time parsing error: $e');

      return 0;
    }
  }

  // ============================================================
  // Get Location with Reverse Geocoding
  // ============================================================

  Future<Map<String, dynamic>?> _getLocationFromCoordinates(
    double lat,
    double lon,
  ) async {
    try {
      debugPrint(
        '📍 Reverse Geocoding request: '
        '$lat, $lon',
      );

      final response = await _dio.get(
        _reverseGeocodingUrl,
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'jsonv2',
          'addressdetails': 1,
          'namedetails': 1,
          'zoom': 10,
          'accept-language': 'fa,en',
        },
        options: Options(
          headers: {
            'User-Agent': 'AetheriaWeatherApp/1.0',
            'Accept-Language': 'fa,en',
          },
        ),
      );

      if (response.statusCode != 200 || response.data is! Map) {
        debugPrint(
          '❌ Reverse Geocoding failed: '
          '${response.statusCode}',
        );

        return null;
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data,
      );

      final dynamic rawAddress = data['address'];

      if (rawAddress is! Map) {
        debugPrint('⚠️ Reverse Geocoding address is missing.');

        return null;
      }

      final Map<String, dynamic> address = Map<String, dynamic>.from(
        rawAddress,
      );

      // --------------------------------------------------------
      // Address city
      // --------------------------------------------------------

      String? cityName;

      final List<String> cityKeys = [
        'city',
        'town',
        'village',
        'municipality',
        'county',
      ];

      for (final key in cityKeys) {
        final value = address[key]?.toString().trim();

        if (value != null && value.isNotEmpty) {
          cityName = value;
          break;
        }
      }

      // --------------------------------------------------------
      // Named details
      // --------------------------------------------------------

      final Map<String, dynamic> nameDetails = data['namedetails'] is Map
          ? Map<String, dynamic>.from(data['namedetails'])
          : {};

      final String? nameFa = _firstNonEmptyString([
        nameDetails['name:fa'],
        nameDetails['name_fa'],
      ]);

      final String? nameEn = _firstNonEmptyString([
        nameDetails['name:en'],
        nameDetails['name_en'],
        nameDetails['int_name'],
      ]);

      // --------------------------------------------------------
      // Select Persian name for WeatherDetailModel.cityName
      //
      // If Persian exists, the home page receives Persian.
      // Otherwise the normal OSM city name is used.
      // --------------------------------------------------------

      final String displayCityName = _cleanCityName(nameFa ?? cityName ?? '');

      final String? state = address['state']?.toString().trim();

      final String? country = address['country']?.toString().trim();

      if (displayCityName.isEmpty) {
        debugPrint('⚠️ No city name found in reverse geocoding.');

        debugPrint('📍 Address data: $address');

        return null;
      }

      debugPrint(
        '✅ Reverse Geocoding success: '
        '$displayCityName | '
        '${state ?? ''} | '
        '${country ?? ''}',
      );

      debugPrint(
        '🇮🇷 Persian Name: '
        '${nameFa ?? ''}',
      );

      debugPrint(
        '🇬🇧 English Name: '
        '${nameEn ?? cityName ?? ''}',
      );

      return {
        'name': displayCityName,
        'nameFa': _cleanCityName(nameFa ?? ''),
        'nameEn': _cleanCityName(nameEn ?? cityName ?? ''),
        'state': state,
        'country': country,
      };
    } on DioException catch (e) {
      debugPrint(
        '❌ Reverse Geocoding Dio error: '
        '${e.response?.statusCode}',
      );

      debugPrint('❌ ${e.response?.data}');

      return null;
    } catch (e) {
      debugPrint('⚠️ OpenStreetMap location error: $e');

      return null;
    }
  }

  // ============================================================
  // Get UV from the main Open-Meteo response
  // ============================================================

  double? _getCurrentUvFromOpenMeteo(Map<String, dynamic> data) {
    try {
      final dynamic current = data['current'];

      if (current is Map) {
        final dynamic rawUv = current['uv_index'];

        if (rawUv is num) {
          return rawUv.toDouble();
        }

        if (rawUv is String) {
          final parsed = double.tryParse(rawUv);

          if (parsed != null) {
            return parsed;
          }
        }
      }

      final dynamic daily = data['daily'];

      if (daily is Map) {
        final dynamic uvMax = daily['uv_index_max'];

        if (uvMax is List && uvMax.isNotEmpty) {
          final dynamic first = uvMax.first;

          if (first is num) {
            return first.toDouble();
          }

          if (first is String) {
            return double.tryParse(first);
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ UV parsing error: $e');

      return null;
    }
  }

  // ============================================================
  // Build daily Forecast from Open-Meteo
  // ============================================================

  List<DailyForecastModel> _buildDailyForecastsFromOpenMeteo(
    Map<String, dynamic> data,
  ) {
    try {
      final dynamic rawDaily = data['daily'];

      if (rawDaily is! Map) {
        return [];
      }

      final Map<String, dynamic> daily = Map<String, dynamic>.from(rawDaily);

      final List<dynamic> dates = daily['time'] is List
          ? List<dynamic>.from(daily['time'])
          : [];

      final List<dynamic> minTemps = daily['temperature_2m_min'] is List
          ? List<dynamic>.from(daily['temperature_2m_min'])
          : [];

      final List<dynamic> maxTemps = daily['temperature_2m_max'] is List
          ? List<dynamic>.from(daily['temperature_2m_max'])
          : [];

      final List<dynamic> weatherCodes = daily['weather_code'] is List
          ? List<dynamic>.from(daily['weather_code'])
          : [];

      final List<dynamic> windSpeeds = daily['wind_speed_10m_max'] is List
          ? List<dynamic>.from(daily['wind_speed_10m_max'])
          : [];

      final int count = dates.length;

      final List<DailyForecastModel> result = [];

      for (int i = 0; i < count; i++) {
        final String date = dates[i]?.toString() ?? '';

        final double minTemp = i < minTemps.length
            ? (_toDouble(minTemps[i]) ?? 0.0)
            : 0.0;

        final double maxTemp = i < maxTemps.length
            ? (_toDouble(maxTemps[i]) ?? 0.0)
            : 0.0;

        final int weatherCode = i < weatherCodes.length
            ? (_toInt(weatherCodes[i]) ?? -1)
            : -1;

        final double windSpeed = i < windSpeeds.length
            ? (_toDouble(windSpeeds[i]) ?? 0.0)
            : 0.0;

        debugPrint(
          '📅 $date | '
          'Code: $weatherCode | '
          'Condition: '
          '${_weatherCodeToMain(weatherCode)} | '
          'Min: '
          '${minTemp.toStringAsFixed(1)}° | '
          'Max: '
          '${maxTemp.toStringAsFixed(1)}° | '
          'Wind Max: '
          '${windSpeed.toStringAsFixed(1)} km/h',
        );

        result.add(
          DailyForecastModel(
            dateTxt: date,
            minTemp: minTemp,
            maxTemp: maxTemp,
            condition: _weatherCodeToMain(weatherCode),
            description: _weatherCodeToDescription(weatherCode),
            icon: _weatherCodeToIcon(weatherCode, true),
            windSpeed: windSpeed,
          ),
        );
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Error building Open-Meteo forecasts: $e');

      debugPrintStack(stackTrace: stackTrace);

      return [];
    }
  }

  // ============================================================
  // Search Cities
  //
  // IMPORTANT:
  // The language of the user's search is detected automatically.
  //
  // Persian query:
  //     تهران
  //     searchLanguage = fa
  //
  // English query:
  //     Tehran
  //     searchLanguage = en
  //
  // This language is stored inside CityGeoModel so the next
  // layer can keep the same language when showing the city.
  // ============================================================

  Future<List<CityGeoModel>> searchCities(String cityName) async {
    try {
      final String query = cityName.trim();

      if (query.isEmpty) {
        return [];
      }

      // --------------------------------------------------------
      // Detect user's search language
      // --------------------------------------------------------

      final String searchLanguage = _isPersianText(query) ? 'fa' : 'en';

      final String acceptLanguage = searchLanguage == 'fa' ? 'fa,en' : 'en,fa';

      debugPrint('🔎 CITY SEARCH: $query');

      debugPrint('🌐 SEARCH LANGUAGE: $searchLanguage');

      debugPrint('🌐 ACCEPT LANGUAGE: $acceptLanguage');

      final response = await _dio.get(
        _nominatimSearchUrl,
        queryParameters: {
          // User's original Persian/English query.
          'q': query,

          // JSON response.
          'format': 'jsonv2',

          // Maximum results.
          'limit': 10,

          // Return address structure.
          'addressdetails': 1,

          // Return all available language variants.
          'namedetails': 1,

          // Search human settlements / cities.
          'featureType': 'settlement',

          // Follow the language used by the user.
          'accept-language': acceptLanguage,
        },
        options: Options(
          headers: {
            'User-Agent': 'AetheriaWeatherApp/1.0',
            'Accept-Language': acceptLanguage,
          },
        ),
      );

      if (response.statusCode != 200 || response.data is! List) {
        debugPrint(
          '❌ Nominatim city search failed: '
          '${response.statusCode}',
        );

        return [];
      }

      final List<dynamic> results = List<dynamic>.from(response.data);

      final List<CityGeoModel> cities = [];

      for (final dynamic item in results) {
        if (item is! Map) {
          continue;
        }

        final Map<String, dynamic> map = Map<String, dynamic>.from(item);

        // ------------------------------------------------------
        // Coordinates
        // ------------------------------------------------------

        final double? lat = _toDouble(map['lat']);

        final double? lon = _toDouble(map['lon']);

        if (lat == null || lon == null) {
          continue;
        }

        // ------------------------------------------------------
        // Address
        // ------------------------------------------------------

        final Map<String, dynamic> address = map['address'] is Map
            ? Map<String, dynamic>.from(map['address'])
            : {};

        // ------------------------------------------------------
        // Named details
        // ------------------------------------------------------

        final Map<String, dynamic> nameDetails = map['namedetails'] is Map
            ? Map<String, dynamic>.from(map['namedetails'])
            : {};

        // ------------------------------------------------------
        // Base OSM name
        // ------------------------------------------------------

        final String? rawName = _firstNonEmptyString([
          map['name'],
          address['city'],
          address['town'],
          address['village'],
          address['municipality'],
          address['county'],
        ]);

        if (rawName == null || rawName.isEmpty) {
          continue;
        }

        // ------------------------------------------------------
        // Persian name
        //
        // No manual translation.
        // Comes from OSM namedetails.
        // ------------------------------------------------------

        final String? nameFa = _firstNonEmptyString([
          nameDetails['name:fa'],
          nameDetails['name_fa'],
        ]);

        // ------------------------------------------------------
        // English name
        //
        // No manual translation.
        // Comes from OSM namedetails.
        // ------------------------------------------------------

        final String? nameEn = _firstNonEmptyString([
          nameDetails['name:en'],
          nameDetails['name_en'],
          nameDetails['int_name'],
        ]);

        // ------------------------------------------------------
        // Country
        // ------------------------------------------------------

        final String? country = _firstNonEmptyString([address['country']]);

        // ------------------------------------------------------
        // State
        // ------------------------------------------------------

        final String? state = _firstNonEmptyString([
          address['state'],
          address['region'],
          address['state_district'],
        ]);

        // ------------------------------------------------------
        // Choose the primary display name according to the
        // language used by the user.
        //
        // Persian search -> Persian name first
        // English search -> English name first
        //
        // If the requested language is unavailable, fallback
        // to the other available name.
        // ------------------------------------------------------

        final String requestedLanguageName = searchLanguage == 'fa'
            ? _cleanCityName(nameFa ?? '')
            : _cleanCityName(nameEn ?? '');

        final String fallbackLanguageName = searchLanguage == 'fa'
            ? _cleanCityName(nameEn ?? '')
            : _cleanCityName(nameFa ?? '');

        final String displayName = requestedLanguageName.isNotEmpty
            ? requestedLanguageName
            : fallbackLanguageName.isNotEmpty
            ? fallbackLanguageName
            : _cleanCityName(rawName);

        if (displayName.isEmpty) {
          continue;
        }

        // ------------------------------------------------------
        // Build CityGeoModel
        // ------------------------------------------------------

        final CityGeoModel city = CityGeoModel.fromJson({
          'name': displayName,

          'nameFa': _cleanCityName(nameFa ?? ''),

          'nameEn': _cleanCityName(nameEn ?? displayName),

          'searchLanguage': searchLanguage,

          'lat': lat,

          'lon': lon,

          'country': country,

          'state': state,
        });

        cities.add(city);

        debugPrint(
          '📍 Search result: '
          '${city.nameFa ?? ''} | '
          '${city.nameEn ?? city.name} | '
          'Language: ${city.searchLanguage} | '
          '$lat,$lon',
        );
      }

      debugPrint(
        '✅ CITY SEARCH RESULTS: '
        '${cities.length}',
      );

      return cities;
    } on DioException catch (e) {
      debugPrint(
        '❌ City search Dio error: '
        '${e.response?.statusCode}',
      );

      debugPrint('❌ ${e.response?.data}');

      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ City search error: $e');

      debugPrintStack(stackTrace: stackTrace);

      return [];
    }
  }

  // ============================================================
  // Detect Persian Text
  // ============================================================
  //
  // If the query contains Persian/Arabic script, it is treated
  // as a Persian search.
  //
  // Examples:
  //     تهران       -> fa
  //     اصفهان      -> fa
  //     مشهد        -> fa
  //
  //     Tehran      -> en
  //     London      -> en
  //     Berlin      -> en
  //
  // Mixed text containing Persian characters is also treated
  // as Persian.
  // ============================================================

  bool _isPersianText(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  // ============================================================
  // Clean City Name
  // ============================================================

  String _cleanCityName(String name) {
    return name
        .replaceFirst(RegExp(r'^شهر\s+'), '')
        .replaceFirst(RegExp(r'^شهرستان\s+'), '')
        .trim();
  }

  // ============================================================
  // Get first valid non-empty string
  // ============================================================

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final dynamic value in values) {
      if (value == null) {
        continue;
      }

      final String text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  // ============================================================
  // Convert Weather Code to weather condition
  //
  // IMPORTANT:
  // This is the single source of truth for mapping
  // Open-Meteo WMO weather_code -> Aetheria condition.
  // ============================================================

  String _weatherCodeToMain(int? code) {
    if (code == null) {
      return 'Unknown';
    }

    switch (code) {
      // --------------------------------------------------------
      // Clear
      // --------------------------------------------------------

      case 0:
        return 'Clear';

      // --------------------------------------------------------
      // Clouds
      // --------------------------------------------------------

      case 1:
      case 2:
      case 3:
        return 'Clouds';

      // --------------------------------------------------------
      // Fog
      // --------------------------------------------------------

      case 45:
      case 48:
        return 'Fog';

      // --------------------------------------------------------
      // Drizzle
      // --------------------------------------------------------

      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'Rain';

      // --------------------------------------------------------
      // Rain
      // --------------------------------------------------------

      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return 'Rain';

      // --------------------------------------------------------
      // Snow
      // --------------------------------------------------------

      case 71:
      case 73:
      case 75:
      case 77:
        return 'Snow';

      // --------------------------------------------------------
      // Rain Showers
      // --------------------------------------------------------

      case 80:
      case 81:
      case 82:
        return 'Rain';

      // --------------------------------------------------------
      // Snow Showers
      // --------------------------------------------------------

      case 85:
      case 86:
        return 'Snow';

      // --------------------------------------------------------
      // Thunderstorm
      // --------------------------------------------------------

      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';

      default:
        return 'Unknown';
    }
  }

  // ============================================================
  // Weather Code description
  // ============================================================

  String _weatherCodeToDescription(int? code) {
    switch (code) {
      case 0:
        return 'clear sky';

      case 1:
        return 'mainly clear';

      case 2:
        return 'partly cloudy';

      case 3:
        return 'overcast';

      case 45:
        return 'fog';

      case 48:
        return 'depositing rime fog';

      case 51:
        return 'light drizzle';

      case 53:
        return 'moderate drizzle';

      case 55:
        return 'dense drizzle';

      case 56:
        return 'light freezing drizzle';

      case 57:
        return 'dense freezing drizzle';

      case 61:
        return 'slight rain';

      case 63:
        return 'moderate rain';

      case 65:
        return 'heavy rain';

      case 66:
        return 'light freezing rain';

      case 67:
        return 'heavy freezing rain';

      case 71:
        return 'slight snow fall';

      case 73:
        return 'moderate snow fall';

      case 75:
        return 'heavy snow fall';

      case 77:
        return 'snow grains';

      case 80:
        return 'slight rain showers';

      case 81:
        return 'moderate rain showers';

      case 82:
        return 'violent rain showers';

      case 85:
        return 'slight snow showers';

      case 86:
        return 'heavy snow showers';

      case 95:
        return 'thunderstorm';

      case 96:
        return 'thunderstorm with slight hail';

      case 99:
        return 'thunderstorm with heavy hail';

      default:
        return 'unknown weather';
    }
  }

  // ============================================================
  // Build Icon similar to OpenWeather
  // ============================================================

  String _weatherCodeToIcon(int? code, dynamic isDay) {
    final bool day = isDay == 1 || isDay == true;

    switch (code) {
      case 0:
        return day ? '01d' : '01n';

      case 1:
        return day ? '02d' : '02n';

      case 2:
        return day ? '03d' : '03n';

      case 3:
        return day ? '04d' : '04n';

      case 45:
      case 48:
        return day ? '50d' : '50n';

      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return day ? '09d' : '09n';

      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return day ? '10d' : '10n';

      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return day ? '13d' : '13n';

      case 95:
      case 96:
      case 99:
        return day ? '11d' : '11n';

      default:
        return day ? '04d' : '04n';
    }
  }

  // ============================================================
  // Safe conversion to int
  // ============================================================

  int? _toInt(dynamic value) {
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

  // ============================================================
  // Safe conversion to double
  // ============================================================

  double? _toDouble(dynamic value) {
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
