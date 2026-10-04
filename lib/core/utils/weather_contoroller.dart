// ============================================================
// weather_contoroller.dart
// ============================================================

import 'dart:math' as math;

class WeatherController {
  static String getBackgroundImage(
    String weatherCondition,
    int sunrise,
    int sunset,
  ) {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final String condition = _normalizeCondition(weatherCondition);

    if (sunrise <= 0 || sunset <= 0 || sunset <= sunrise) {
      return _getFallbackBackground(condition);
    }

    // ==========================================================
    // Sunrise
    // ==========================================================

    final int sunriseStart = sunrise;

    final int sunriseEnd = math.min(
      sunrise + const Duration(hours: 1).inSeconds,
      sunset,
    );

    // ==========================================================
    // Sunset
    // ==========================================================

    final int sunsetStart = math.max(
      sunset - const Duration(hours: 1).inSeconds,
      sunriseEnd,
    );

    final int sunsetEnd = sunset + const Duration(hours: 1).inSeconds;

    // ==========================================================
    // Current time state
    // ==========================================================

    final bool isSunrise = now >= sunriseStart && now < sunriseEnd;

    final bool isSunset = now >= sunsetStart && now < sunsetEnd;

    final bool isNight = now < sunriseStart || now >= sunsetEnd;

    final bool isDay = now >= sunriseEnd && now < sunsetStart;

    // ==========================================================
    // Debug
    // ==========================================================

    print(
      '🌅 Background Time → '
      'now=$now | '
      'sunrise=$sunrise | '
      'sunset=$sunset | '
      'sunrisePeriod=$isSunrise | '
      'sunsetPeriod=$isSunset | '
      'day=$isDay | '
      'night=$isNight | '
      'condition=$condition | '
      'apiCondition=$weatherCondition',
    );

    switch (condition) {
      // ========================================================
      // THUNDERSTORM
      // ========================================================

      case 'thunderstorm':
        if (isNight) {
          return 'assets/images/Gemini_Generated_Image_.jfif';
        }

        return 'assets/images/Gemini_Generated_Image_ibqxrlibqxrlibqx.jpg';

      // ========================================================
      // SNOW
      // ========================================================

      case 'snow':
        if (isNight) {
          return 'assets/images/Gemini_Generated_Image_yve5r6yve5r6yve5.jpg';
        }

        return 'assets/images/Gemini_Generated_Image_ (2).png';

      // ========================================================
      // RAIN
      // ========================================================

      case 'rain':
      case 'drizzle':

        // ------------------------------------------------------
        // Rain + Night
        // ------------------------------------------------------

        if (isNight) {
          return 'assets/images/Gemini_Generated_Image_udh2zqudh2zqudh2.jpg';
        }

        // ------------------------------------------------------

        return 'assets/images/Gemini_Generated_Image_ub7962ub7962ub79.jpg';

      // ========================================================
      // FOG
      // ========================================================

      case 'fog':
        if (isNight) {
          return 'assets/images/fog_night.png';
        }

        return 'assets/images/Gemini_Generated_Image_ (1).png';

      // ========================================================
      // CLOUDS
      // ========================================================

      case 'clouds':
        if (isNight) {
          return 'assets/images/Gemini_Generated_Image_iojod7iojod7iojo.jpg';
        }

        return 'assets/images/Gemini_Generated_Image_.png';

      // ========================================================
      // CLEAR
      // ========================================================

      case 'clear':

        // ------------------------------------------------------
        // Clear Night
        // ------------------------------------------------------

        if (isNight) {
          return 'assets/images/Gemini_Generated_Image_ (3).png';
        }

        // ------------------------------------------------------
        // Clear Sunrise
        // ------------------------------------------------------

        if (isSunrise) {
          return 'assets/images/Gemini_Generated_Image_plv5raplv5raplv5.jpg';
        }

        // ------------------------------------------------------
        // Clear Sunset
        // ------------------------------------------------------

        if (isSunset) {
          return 'assets/images/Gemini_Generated_Image_ (4).png';
        }

        // ------------------------------------------------------
        // Clear Day
        // ------------------------------------------------------

        if (isDay) {
          return 'assets/images/Gemini_Generated_Image_umwt82umwt82umwt.jpg';
        }

        return 'assets/images/Gemini_Generated_Image_umwt82umwt82umwt.jpg';

      // ========================================================
      // UNKNOWN
      // ========================================================

      default:
        return _getFallbackBackground(condition);
    }
  }

  // ============================================================
  // NORMALIZE WEATHER CONDITION
  // ============================================================

  static String _normalizeCondition(String weatherCondition) {
    final String value = weatherCondition
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    if (value.isEmpty) {
      return 'unknown';
    }

    // ==========================================================
    //
    // ==========================================================

    final int? weatherCode = int.tryParse(value);

    if (weatherCode != null) {
      return _conditionFromWmoCode(weatherCode);
    }

    // ==========================================================
    // THUNDERSTORM
    // ==========================================================

    if (value.contains('thunder') ||
        value.contains('storm') ||
        value.contains('lightning') ||
        value.contains('squall')) {
      return 'thunderstorm';
    }

    // ==========================================================
    // SNOW
    // ==========================================================

    if (value.contains('snow') ||
        value.contains('sleet') ||
        value.contains('freezing rain') ||
        value.contains('ice')) {
      return 'snow';
    }

    // ==========================================================
    // FOG
    // ==========================================================

    if (value.contains('fog') ||
        value.contains('mist') ||
        value.contains('haze') ||
        value.contains('smoke')) {
      return 'fog';
    }

    // ==========================================================
    // RAIN
    // ==========================================================

    if (value.contains('rain') ||
        value.contains('drizzle') ||
        value.contains('shower')) {
      return 'rain';
    }

    // ==========================================================
    // CLOUDS
    // ==========================================================

    if (value.contains('cloud') || value.contains('overcast')) {
      return 'clouds';
    }

    // ==========================================================
    // CLEAR
    // ==========================================================

    if (value.contains('clear') ||
        value.contains('sunny') ||
        value.contains('sun')) {
      return 'clear';
    }

    // ==========================================================
    // Exact values
    // ==========================================================

    switch (value) {
      case 'thunderstorm':
      case 'lightning':
      case 'thunder':
      case 'squall':
        return 'thunderstorm';

      case 'snow':
      case 'sleet':
      case 'ice':
        return 'snow';

      case 'rain':
      case 'drizzle':
      case 'shower':
      case 'shower rain':
      case 'rain showers':
      case 'freezing rain':
        return 'rain';

      case 'fog':
      case 'mist':
      case 'haze':
      case 'smoke':
        return 'fog';

      case 'clouds':
      case 'cloudy':
      case 'overcast':
        return 'clouds';

      case 'clear':
      case 'sunny':
      case 'clear sky':
        return 'clear';

      default:
        return 'unknown';
    }
  }

  // ============================================================
  // OPEN-METEO WMO WEATHER CODE
  // ============================================================

  static String _conditionFromWmoCode(int code) {
    // ==========================================================
    // 0 = Clear sky
    // ==========================================================

    if (code == 0) {
      return 'clear';
    }

    // ==========================================================
    // 1, 2, 3 = Mainly clear / Partly cloudy / Overcast
    // ==========================================================

    if (code >= 1 && code <= 3) {
      return 'clouds';
    }

    // ==========================================================
    // 45, 48 = Fog
    // ==========================================================

    if (code == 45 || code == 48) {
      return 'fog';
    }

    // ==========================================================
    // 51, 53, 55 = Drizzle
    // ==========================================================

    if (code >= 51 && code <= 55) {
      return 'rain';
    }

    // ==========================================================
    // 56, 57 = Freezing drizzle
    // ==========================================================

    if (code == 56 || code == 57) {
      return 'rain';
    }

    // ==========================================================
    // 61, 63, 65 = Rain
    // ==========================================================

    if (code >= 61 && code <= 65) {
      return 'rain';
    }

    // ==========================================================
    // 66, 67 = Freezing rain
    // ==========================================================

    if (code == 66 || code == 67) {
      return 'rain';
    }

    // ==========================================================
    // 71, 73, 75, 77 = Snow
    // ==========================================================

    if (code == 71 || code == 73 || code == 75 || code == 77) {
      return 'snow';
    }

    // ==========================================================
    // 80, 81, 82 = Rain showers
    // ==========================================================

    if (code >= 80 && code <= 82) {
      return 'rain';
    }

    // ==========================================================
    // 85, 86 = Snow showers
    // ==========================================================

    if (code == 85 || code == 86) {
      return 'snow';
    }

    // ==========================================================
    // 95, 96, 99 = Thunderstorm
    // ==========================================================

    if (code == 95 || code == 96 || code == 99) {
      return 'thunderstorm';
    }

    return 'unknown';
  }

  // ============================================================
  // FALLBACK
  // ============================================================

  static String _getFallbackBackground(String weatherCondition) {
    final String condition = _normalizeCondition(weatherCondition);

    switch (condition) {
      case 'thunderstorm':
        return 'assets/images/Gemini_Generated_Image_ibqxrlibqxrlibqx.jpg';

      case 'snow':
        return 'assets/images/Gemini_Generated_Image_ (2).png';

      case 'rain':
      case 'drizzle':
        return 'assets/images/Gemini_Generated_Image_ub7962ub7962ub79.jpg';

      case 'fog':
        return 'assets/images/Gemini_Generated_Image_ (1).png';

      case 'clouds':
        return 'assets/images/Gemini_Generated_Image_.png';

      case 'clear':
        return 'assets/images/Gemini_Generated_Image_umwt82umwt82umwt.jpg';

      default:
        return 'assets/images/Gemini_Generated_Image_.png';
    }
  }
}
