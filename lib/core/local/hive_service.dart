import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../features/weather/data/models/weather_detail_model.dart';

class HiveService {
  static const String _boxName = 'weatherBox';

  // ============================================================
  // Previous key - to prevent breaking the previous structure
  // ============================================================

  static const String _weatherKey = 'latestWeather';

  // ============================================================
  // Saved cities
  //
  // The order of this list is also the persistent order of cities.
  // ============================================================

  static const String _savedCitiesKey = 'savedCities';

  // Maximum number of cities that can be saved
  static const int maxSavedCities = 20;

  static Box? _box;

  // ============================================================
  // INIT
  // ============================================================

  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox(_boxName);
      } else {
        _box = Hive.box(_boxName);
      }

      debugPrint('✅ Hive initialized successfully.');
    } catch (e) {
      debugPrint('❌ Hive initialization error: $e');
    }
  }

  // ============================================================
  // SAVE WEATHER
  //
  // Only cache the latest weather status.
  //
  // This method does not add the city to savedCities.
  // ============================================================

  static Future<void> saveWeather(WeatherDetailModel weather) async {
    try {
      if (_box == null || !_box!.isOpen) {
        await init();
      }

      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ Hive box is not available.');
        return;
      }

      final Map<String, dynamic> weatherMap = _weatherToMap(weather);

      await _box!.put(_weatherKey, weatherMap);

      debugPrint(
        '✅ Weather saved to Hive successfully. '
        'City: ${weather.cityName} | '
        'UV: ${weather.uvIndex} | '
        'Next Sunrise: ${weather.nextSunrise}',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving weather to Hive: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // GET WEATHER
  //
  // Only cache the latest weather status.
  // ============================================================

  static WeatherDetailModel? getWeather() {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('⚠️ Hive box is not open.');
        return null;
      }

      final dynamic weatherData = _box!.get(_weatherKey);

      if (weatherData == null) {
        debugPrint('ℹ️ No cached weather found.');
        return null;
      }

      if (weatherData is! Map) {
        debugPrint('❌ Cached weather data is not a valid Map.');
        return null;
      }

      final Map<String, dynamic> weatherMap = Map<String, dynamic>.from(
        weatherData,
      );

      final WeatherDetailModel weatherModel = WeatherDetailModel.fromCacheJson(
        weatherMap,
      );

      debugPrint(
        '✅ Weather loaded from Hive. '
        'City: ${weatherModel.cityName} | '
        'UV: ${weatherModel.uvIndex} | '
        'Next Sunrise: ${weatherModel.nextSunrise}',
      );

      return weatherModel;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting weather from Hive: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }

  // ============================================================
  // HAS WEATHER
  // ============================================================

  static bool hasWeather() {
    try {
      if (_box == null || !_box!.isOpen) {
        return false;
      }

      return _box!.containsKey(_weatherKey);
    } catch (e) {
      debugPrint('❌ Error checking cached weather: $e');
      return false;
    }
  }

  // ============================================================
  // SAVE CITY WEATHER
  //
  // Only this method adds a city to Saved Cities.
  //
  // IMPORTANT:
  // The existing list order is preserved.
  // ============================================================

  static Future<bool> saveCityWeather(WeatherDetailModel weather) async {
    try {
      if (_box == null || !_box!.isOpen) {
        await init();
      }

      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ Hive box is not available.');
        return false;
      }

      final List<Map<String, dynamic>> cities = _getSavedCitiesRaw();

      final String cityKey = _buildCityKey(weather);

      final Map<String, dynamic> weatherMap = _weatherToMap(weather);

      // ----------------------------------------------------------
      // Existing city
      // ----------------------------------------------------------

      final int existingIndex = cities.indexWhere(
        (city) => city['city_key']?.toString() == cityKey,
      );

      if (existingIndex != -1) {
        cities[existingIndex] = {'city_key': cityKey, 'weather': weatherMap};

        await _box!.put(_savedCitiesKey, cities);

        debugPrint('🔄 Saved city updated: ${weather.cityName}');

        return true;
      }

      // ----------------------------------------------------------
      // New city
      // ----------------------------------------------------------

      if (cities.length >= maxSavedCities) {
        debugPrint(
          '⚠️ Maximum saved cities reached: '
          '$maxSavedCities',
        );

        return false;
      }

      cities.add({'city_key': cityKey, 'weather': weatherMap});

      await _box!.put(_savedCitiesKey, cities);

      debugPrint(
        '✅ City saved successfully: '
        '${weather.cityName} '
        '(${cities.length}/$maxSavedCities)',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving city weather: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // ============================================================
  // REORDER SAVED CITIES
  //
  // This is the persistent source of truth for city ordering.
  //
  // oldIndex/newIndex follow Flutter's ReorderableListView
  // convention: newIndex must already be adjusted by the caller.
  // ============================================================

  static Future<bool> reorderSavedCities(int oldIndex, int newIndex) async {
    try {
      if (_box == null || !_box!.isOpen) {
        await init();
      }

      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ Hive box is not available.');
        return false;
      }

      final cities = _getSavedCitiesRaw();

      if (oldIndex < 0 ||
          oldIndex >= cities.length ||
          newIndex < 0 ||
          newIndex >= cities.length) {
        debugPrint(
          '⚠️ Invalid reorder indexes: '
          '$oldIndex -> $newIndex',
        );

        return false;
      }

      if (oldIndex == newIndex) {
        return true;
      }

      final movedCity = cities.removeAt(oldIndex);

      cities.insert(newIndex, movedCity);

      await _box!.put(_savedCitiesKey, cities);

      debugPrint(
        '🔀 Saved cities reordered: '
        '$oldIndex -> $newIndex',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error reordering saved cities: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // ============================================================
  // GET SAVED CITIES
  //
  // The order returned here is exactly the order stored in Hive.
  // ============================================================

  static List<WeatherDetailModel> getSavedCities() {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('⚠️ Hive box is not open.');
        return [];
      }

      final List<Map<String, dynamic>> cities = _getSavedCitiesRaw();

      final List<WeatherDetailModel> result = [];

      for (final city in cities) {
        try {
          final dynamic weatherData = city['weather'];

          if (weatherData is! Map) {
            continue;
          }

          final weatherMap = Map<String, dynamic>.from(weatherData);

          final weather = WeatherDetailModel.fromCacheJson(weatherMap);

          result.add(weather);
        } catch (e) {
          debugPrint('⚠️ Failed to load saved city: $e');
        }
      }

      debugPrint('📦 Saved cities loaded: ${result.length}');

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting saved cities: $e');
      debugPrint('$stackTrace');
      return [];
    }
  }

  // ============================================================
  // GET SAVED CITY BY INDEX
  // ============================================================

  static WeatherDetailModel? getSavedCity(int index) {
    try {
      final cities = getSavedCities();

      if (index < 0 || index >= cities.length) {
        return null;
      }

      return cities[index];
    } catch (e) {
      debugPrint('❌ Error getting saved city: $e');
      return null;
    }
  }

  // ============================================================
  // GET SAVED CITIES COUNT
  // ============================================================

  static int getSavedCitiesCount() {
    try {
      if (_box == null || !_box!.isOpen) {
        return 0;
      }

      return _getSavedCitiesRaw().length;
    } catch (e) {
      debugPrint('❌ Error getting saved cities count: $e');
      return 0;
    }
  }

  // ============================================================
  // HAS SAVED CITY
  // ============================================================

  static bool hasSavedCity(WeatherDetailModel weather) {
    try {
      if (_box == null || !_box!.isOpen) {
        return false;
      }

      final cities = _getSavedCitiesRaw();

      final cityKey = _buildCityKey(weather);

      return cities.any((city) => city['city_key']?.toString() == cityKey);
    } catch (e) {
      debugPrint('❌ Error checking saved city: $e');
      return false;
    }
  }

  // ============================================================
  // REMOVE SAVED CITY
  //
  // Delete only from Saved Cities.
  //
  // Because the saved city list itself stores the order,
  // removing an item automatically keeps the remaining order.
  // ============================================================

  static Future<bool> removeSavedCity(WeatherDetailModel weather) async {
    try {
      if (_box == null || !_box!.isOpen) {
        await init();
      }

      if (_box == null || !_box!.isOpen) {
        return false;
      }

      final cities = _getSavedCitiesRaw();

      final cityKey = _buildCityKey(weather);

      final oldLength = cities.length;

      cities.removeWhere((city) => city['city_key']?.toString() == cityKey);

      if (cities.length == oldLength) {
        return false;
      }

      if (cities.isEmpty) {
        await _box!.delete(_savedCitiesKey);
      } else {
        await _box!.put(_savedCitiesKey, cities);
      }

      debugPrint('🗑️ Saved city removed: ${weather.cityName}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error removing saved city: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // ============================================================
  // CLEAR SAVED CITIES
  //
  // Only Saved Cities will be cleared.
  //
  // latestWeather remains untouched.
  // ============================================================

  static Future<void> clearSavedCities() async {
    try {
      if (_box == null || !_box!.isOpen) {
        await init();
      }

      if (_box == null || !_box!.isOpen) {
        return;
      }

      await _box!.delete(_savedCitiesKey);

      debugPrint('🗑️ Saved cities cleared.');
    } catch (e, stackTrace) {
      debugPrint('❌ Error clearing saved cities: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // PRIVATE - GET RAW SAVED CITIES
  // ============================================================

  static List<Map<String, dynamic>> _getSavedCitiesRaw() {
    try {
      if (_box == null || !_box!.isOpen) {
        return [];
      }

      final dynamic rawData = _box!.get(_savedCitiesKey);

      if (rawData is! List) {
        return [];
      }

      final List<Map<String, dynamic>> result = [];

      for (final item in rawData) {
        if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error reading saved cities raw data: $e');
      return [];
    }
  }

  // ============================================================
  // PRIVATE - BUILD CITY KEY
  //
  // The city is identified based on coordinates.
  // ============================================================

  static String _buildCityKey(WeatherDetailModel weather) {
    return '${weather.latitude.toStringAsFixed(6)}_'
        '${weather.longitude.toStringAsFixed(6)}';
  }

  // ============================================================
  // PRIVATE - WEATHER -> MAP
  // ============================================================

  static Map<String, dynamic> _weatherToMap(WeatherDetailModel weather) {
    final serializedForecast = weather.forecast
        .map((forecast) => forecast.toJson())
        .toList();

    return {
      'city_name': weather.cityName,
      'country': weather.country,
      'state': weather.state,

      'latitude': weather.latitude,
      'longitude': weather.longitude,

      'temp': weather.temp,
      'feels_like': weather.feelsLike,

      'pressure': weather.pressure,
      'humidity': weather.humidity,

      'wind_speed': weather.windSpeed,
      'wind_deg': weather.windDeg,

      'uv_index': weather.uvIndex,

      'weather_main': weather.weatherMain,
      'weather_description': weather.weatherDescription,
      'weather_icon': weather.weatherIcon,

      'sunrise': weather.sunrise,
      'sunset': weather.sunset,

      'next_sunrise': weather.nextSunrise,

      'timezone': weather.timezone,

      'forecast': serializedForecast,
    };
  }

  // ============================================================
  // CLEAR WEATHER
  //
  // Only clears latestWeather.
  // ============================================================

  static Future<void> clearWeather() async {
    try {
      if (_box == null || !_box!.isOpen) {
        await init();
      }

      if (_box == null || !_box!.isOpen) {
        return;
      }

      await _box!.delete(_weatherKey);

      debugPrint('🗑️ Cached weather cleared.');
    } catch (e, stackTrace) {
      debugPrint('❌ Error clearing weather: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // CLEAR ALL
  //
  // All Hive data will be cleared.
  // ============================================================

  static Future<void> clearAll() async {
    try {
      if (_box == null || !_box!.isOpen) {
        await init();
      }

      if (_box == null || !_box!.isOpen) {
        return;
      }

      await _box!.clear();

      debugPrint('🗑️ All Hive data cleared.');
    } catch (e, stackTrace) {
      debugPrint('❌ Error clearing Hive data: $e');
      debugPrint('$stackTrace');
    }
  }
}
