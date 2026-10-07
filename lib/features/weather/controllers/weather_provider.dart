import 'dart:async';
import 'dart:io';

import 'package:aetheria/core/local/hive_service.dart';
import 'package:aetheria/core/utils/location_service.dart';
import 'package:aetheria/core/utils/weather_contoroller.dart';
import 'package:aetheria/features/weather/data/models/weather_detail_model.dart';
import 'package:aetheria/features/weather/data/repositories/weather_repository.dart';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

class WeatherProvider extends ChangeNotifier with WidgetsBindingObserver {
  final WeatherRepository _repository = WeatherRepository();
  final LocationService _locationService = LocationService();

  Timer? _backgroundTimer;
  Timer? _weatherUpdateTimer;

  String _backgroundImage = 'assets/images/Gemini_Generated_Image_.png';

  String get backgroundImage => _backgroundImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  WeatherDetailModel? _weatherData;
  WeatherDetailModel? get weatherData => _weatherData;

  final List<WeatherDetailModel> _savedCities = [];

  List<WeatherDetailModel> get savedCities => List.unmodifiable(_savedCities);

  int _currentCityIndex = 0;
  int get currentCityIndex => _currentCityIndex;

  bool get hasMultipleCities => _savedCities.length > 1;

  int get savedCitiesCount => _savedCities.length;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _showLocationInitialError = false;
  bool get showLocationInitialError => _showLocationInitialError;

  bool _showLocationRefreshError = false;
  bool get showLocationRefreshError => _showLocationRefreshError;

  bool get hasData => _weatherData != null;

  bool get isFirstLoad => _isLoading && !hasData;

  bool get shouldShowLocationError =>
      (_showLocationInitialError || _showLocationRefreshError) && !hasData;

  bool get shouldShowError =>
      _errorMessage != null && !hasData && !shouldShowLocationError;

  WeatherProvider() {
    WidgetsBinding.instance.addObserver(this);

    _loadCachedWeather();
    _startBackgroundTimer();
    _startWeatherUpdateTimer();
  }

  // ============================================================
  // INTERNET
  // ============================================================

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> initializeLocation() async {
    final bool hasCachedData = _weatherData != null;

    if (!hasCachedData) {
      _isLoading = true;
      _errorMessage = null;
      _showLocationInitialError = false;
      _showLocationRefreshError = false;

      notifyListeners();
    }

    try {
      final hasInternet = await _hasInternet();

      if (!hasInternet) {
        if (!hasCachedData) {
          _errorMessage = 'Internet connection is not available.';
        }

        return;
      }

      LocationPermission permission = await _locationService
          .checkLocationPermission();

      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestLocationPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!hasCachedData) {
          _errorMessage = 'Location access is required.';
        }

        return;
      }

      final isLocationEnabled = await _locationService
          .isLocationServiceEnabled();

      if (!isLocationEnabled) {
        if (!hasCachedData) {
          _showLocationInitialError = true;
          _errorMessage = 'The phone location service is turned off.';
        }

        return;
      }

      Position? position = await _locationService.getCurrentLocation();

      if (position == null) {
        await Future.delayed(const Duration(milliseconds: 700));

        position = await _locationService.getCurrentLocation();
      }

      if (position == null) {
        if (!hasCachedData) {
          _errorMessage = 'Failed to get the current location.';
        }

        return;
      }

      await _fetchWeather(position);
    } catch (e) {
      if (!hasCachedData) {
        _errorMessage = 'An error occurred while retrieving information.';
      }
    } finally {
      if (!hasCachedData) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> checkLocationAfterResume() async {
    await initializeLocation();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshWeather() async {
    if (_isLoading) {
      return;
    }

    _errorMessage = null;
    _showLocationRefreshError = false;

    final hasInternet = await _hasInternet();

    if (!hasInternet) {
      _errorMessage = 'Internet connection is not available.';

      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (_weatherData != null) {
        await _refreshActiveCityWeather();
        return;
      }

      final isLocationEnabled = await _locationService
          .isLocationServiceEnabled();

      if (!isLocationEnabled) {
        _showLocationRefreshError = true;
        _errorMessage = 'Turn on location to get updated information.';

        return;
      }

      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        await _fetchWeather(position);
      } else {
        _errorMessage = 'Failed to get the current location.';
      }
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
      _errorMessage = 'Update failed.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH ACTIVE CITY
  // ============================================================

  Future<void> _refreshActiveCityWeather() async {
    final activeWeather = _weatherData;

    if (activeWeather == null) {
      return;
    }

    debugPrint('========================================');
    debugPrint('🔄 REFRESH ACTIVE CITY');
    debugPrint('🏙️ City: ${activeWeather.cityName}');
    debugPrint('📍 Lat: ${activeWeather.latitude}');
    debugPrint('📍 Lon: ${activeWeather.longitude}');
    debugPrint('========================================');

    final updatedWeather = await _repository.getWeatherDetails(
      activeWeather.latitude,
      activeWeather.longitude,
    );

    if (updatedWeather == null) {
      _errorMessage = 'Failed to get weather information for the city.';
      return;
    }

    final refreshedWeather = updatedWeather.copyWith(
      cityName: activeWeather.cityName,
      cityNameFa: activeWeather.cityNameFa,
      cityNameEn: activeWeather.cityNameEn,
      state: activeWeather.state,
      country: activeWeather.country,
    );

    final activeCityIndex = _findCityIndex(activeWeather);

    if (activeCityIndex >= 0) {
      _savedCities[activeCityIndex] = refreshedWeather;

      _currentCityIndex = activeCityIndex;
    }

    _weatherData = refreshedWeather;

    _errorMessage = null;
    _showLocationInitialError = false;
    _showLocationRefreshError = false;

    _updateBackgroundImage(refreshedWeather);

    await HiveService.saveWeather(refreshedWeather);

    if (activeCityIndex >= 0) {
      await HiveService.saveCityWeather(refreshedWeather);
    }

    debugPrint('========================================');
    debugPrint('✅ ACTIVE CITY WEATHER UPDATED');
    debugPrint('🏙️ City: ${refreshedWeather.cityName}');
    debugPrint('🌡️ Temp: ${refreshedWeather.temp}');
    debugPrint('🌤️ Main: ${refreshedWeather.weatherMain}');
    debugPrint(
      '🌤️ Description: '
      '${refreshedWeather.weatherDescription}',
    );
    debugPrint('========================================');
  }

  // ============================================================
  // FETCH WEATHER
  // ============================================================

  Future<void> _fetchWeather(Position position) async {
    final weatherDetail = await _repository.getWeatherDetails(
      position.latitude,
      position.longitude,
    );

    if (weatherDetail == null) {
      _errorMessage = 'Failed to get weather information.';
      return;
    }

    _weatherData = weatherDetail;

    _errorMessage = null;
    _showLocationInitialError = false;
    _showLocationRefreshError = false;
    _isLoading = false;

    debugPrint(
      '🌤️ Weather Main: '
      '${weatherDetail.weatherMain}',
    );

    debugPrint(
      '🌤️ Weather Description: '
      '${weatherDetail.weatherDescription}',
    );

    debugPrint(
      '🌤️ Weather Icon: '
      '${weatherDetail.weatherIcon}',
    );

    debugPrint('🌅 Sunrise: ${weatherDetail.sunrise}');

    debugPrint('🌇 Sunset: ${weatherDetail.sunset}');

    debugPrint('🌍 Timezone: ${weatherDetail.timezone}');

    _updateBackgroundImage(weatherDetail);

    await HiveService.saveWeather(weatherDetail);

    await _updateMatchingSavedCity(weatherDetail);

    notifyListeners();
  }

  // ============================================================
  // SELECT CITY
  // ============================================================

  Future<bool> selectCity(CityGeoModel city) async {
    if (_isLoading) {
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;

      notifyListeners();

      debugPrint('========================================');
      debugPrint('🏙️ SELECT CITY');
      debugPrint('🏙️ Name: ${city.name}');
      debugPrint('🇮🇷 Persian Name: ${city.nameFa}');
      debugPrint('🇬🇧 English Name: ${city.nameEn}');
      debugPrint('🌍 Country: ${city.country}');
      debugPrint('📍 State: ${city.state}');
      debugPrint('📍 Lat: ${city.lat}');
      debugPrint('📍 Lon: ${city.lon}');
      debugPrint('========================================');

      final weather = await _repository.getWeatherDetails(city.lat, city.lon);

      if (weather == null) {
        _errorMessage = 'Failed to get weather information for the city.';
        return false;
      }

      final updatedWeather = weather.copyWith(
        cityName: city.name,
        cityNameFa: city.nameFa,
        cityNameEn: city.nameEn,
        state: city.state,
        country: city.country,
      );

      _addOrUpdateSavedCity(updatedWeather);

      final savedToHive = await HiveService.saveCityWeather(updatedWeather);

      if (!savedToHive) {
        debugPrint(
          '⚠️ City could not be persisted in Hive: '
          '${updatedWeather.cityName}',
        );
      }

      final index = _findCityIndex(updatedWeather);

      if (index >= 0) {
        _currentCityIndex = index;
      }

      _weatherData = updatedWeather;

      _errorMessage = null;
      _showLocationInitialError = false;
      _showLocationRefreshError = false;

      _updateBackgroundImage(updatedWeather);

      await HiveService.saveWeather(updatedWeather);

      debugPrint('========================================');
      debugPrint('✅ CITY SELECTED');
      debugPrint('🏙️ City: ${updatedWeather.cityName}');
      debugPrint('🇮🇷 Persian: ${updatedWeather.cityNameFa}');
      debugPrint('🇬🇧 English: ${updatedWeather.cityNameEn}');
      debugPrint('🌡️ Temp: ${updatedWeather.temp}');
      debugPrint('📦 Saved Cities: ${_savedCities.length}');
      debugPrint('========================================');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Select city error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Failed to get city information.';

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ADD CITY
  // ============================================================

  Future<bool> addCity(CityGeoModel city, {WeatherDetailModel? weather}) async {
    try {
      debugPrint('========================================');
      debugPrint('➕ ADD CITY');
      debugPrint('🏙️ Name: ${city.name}');
      debugPrint('🇮🇷 Persian Name: ${city.nameFa}');
      debugPrint('🇬🇧 English Name: ${city.nameEn}');
      debugPrint('🌍 Country: ${city.country}');
      debugPrint('📍 State: ${city.state}');
      debugPrint('📍 Lat: ${city.lat}');
      debugPrint('📍 Lon: ${city.lon}');
      debugPrint('========================================');

      final existingIndex = _findCityIndexByCoordinates(city.lat, city.lon);

      if (existingIndex >= 0) {
        debugPrint(
          'ℹ️ City already exists at index '
          '$existingIndex',
        );

        return true;
      }

      if (_savedCities.length >= HiveService.maxSavedCities) {
        _errorMessage =
            'A maximum of '
            '${HiveService.maxSavedCities} '
            'cities can be saved.';

        notifyListeners();

        return false;
      }

      WeatherDetailModel? cityWeather = weather;

      cityWeather ??= await _repository.getWeatherDetails(city.lat, city.lon);

      if (cityWeather == null) {
        _errorMessage = 'Failed to get weather information for the city.';

        notifyListeners();

        return false;
      }

      final updatedWeather = cityWeather.copyWith(
        cityName: city.name,
        cityNameFa: city.nameFa,
        cityNameEn: city.nameEn,
        state: city.state,
        country: city.country,
      );

      final savedToHive = await HiveService.saveCityWeather(updatedWeather);

      if (!savedToHive) {
        _errorMessage = 'Failed to save the city.';

        notifyListeners();

        return false;
      }

      _savedCities.add(updatedWeather);

      _errorMessage = null;

      debugPrint(
        '✅ City added successfully: '
        '${updatedWeather.cityName}',
      );

      debugPrint(
        '📦 Total saved cities: '
        '${_savedCities.length}',
      );

      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Add city error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Failed to add the city.';

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // ADD OR UPDATE SAVED CITY
  // ============================================================

  void _addOrUpdateSavedCity(WeatherDetailModel weather) {
    final existingIndex = _findCityIndex(weather);

    if (existingIndex >= 0) {
      _savedCities[existingIndex] = weather;

      debugPrint('🔄 City updated at index $existingIndex');

      return;
    }

    if (_savedCities.length >= HiveService.maxSavedCities) {
      debugPrint(
        '⚠️ Maximum saved cities reached: '
        '${HiveService.maxSavedCities}',
      );

      return;
    }

    _savedCities.add(weather);

    debugPrint(
      '➕ City added. Total cities: '
      '${_savedCities.length}',
    );
  }

  // ============================================================
  // REORDER SAVED CITIES
  //
  // This method is shared by SearchCityPage and Home.
  // ============================================================

  Future<bool> reorderSavedCities(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _savedCities.length ||
        newIndex < 0 ||
        newIndex >= _savedCities.length) {
      return false;
    }

    if (oldIndex == newIndex) {
      return true;
    }

    final activeCity = _weatherData;

    final originalCities = List<WeatherDetailModel>.from(_savedCities);

    final movedCity = _savedCities.removeAt(oldIndex);

    _savedCities.insert(newIndex, movedCity);

    // ----------------------------------------------------------
    // Keep the same city active after reordering.
    // ----------------------------------------------------------

    if (activeCity != null) {
      final newActiveIndex = _findCityIndex(activeCity);

      if (newActiveIndex >= 0) {
        _currentCityIndex = newActiveIndex;
      }
    } else {
      _currentCityIndex = _currentCityIndex
          .clamp(0, _savedCities.length - 1)
          .toInt();
    }

    final saved = await HiveService.reorderSavedCities(oldIndex, newIndex);

    if (!saved) {
      _savedCities
        ..clear()
        ..addAll(originalCities);

      if (activeCity != null) {
        final restoredIndex = _findCityIndex(activeCity);

        if (restoredIndex >= 0) {
          _currentCityIndex = restoredIndex;
        }
      }

      return false;
    }

    debugPrint(
      '🔀 Provider cities reordered: '
      '$oldIndex -> $newIndex',
    );

    debugPrint(
      '📦 New order: '
      '${_savedCities.map((city) => city.cityName).join(' → ')}',
    );

    notifyListeners();

    return true;
  }

  // ============================================================
  // FIND CITY
  // ============================================================

  int _findCityIndex(WeatherDetailModel weather) {
    for (int i = 0; i < _savedCities.length; i++) {
      final saved = _savedCities[i];

      if (_sameCity(saved, weather)) {
        return i;
      }
    }

    return -1;
  }

  int _findCityIndexByCoordinates(double latitude, double longitude) {
    for (int i = 0; i < _savedCities.length; i++) {
      final saved = _savedCities[i];

      final latDifference = (saved.latitude - latitude).abs();

      final lonDifference = (saved.longitude - longitude).abs();

      if (latDifference < 0.001 && lonDifference < 0.001) {
        return i;
      }
    }

    return -1;
  }

  bool _sameCity(WeatherDetailModel first, WeatherDetailModel second) {
    final latDifference = (first.latitude - second.latitude).abs();

    final lonDifference = (first.longitude - second.longitude).abs();

    return latDifference < 0.001 && lonDifference < 0.001;
  }

  // ============================================================
  // UPDATE MATCHING SAVED CITY
  // ============================================================

  Future<void> _updateMatchingSavedCity(WeatherDetailModel weather) async {
    final index = _findCityIndex(weather);

    if (index < 0) {
      return;
    }

    final savedCity = _savedCities[index];

    final updatedWeather = weather.copyWith(
      cityName: savedCity.cityName,
      cityNameFa: savedCity.cityNameFa,
      cityNameEn: savedCity.cityNameEn,
      state: savedCity.state,
      country: savedCity.country,
    );

    _savedCities[index] = updatedWeather;

    if (index == _currentCityIndex) {
      _weatherData = updatedWeather;
    }

    await HiveService.saveCityWeather(updatedWeather);

    debugPrint(
      '🔄 Saved city weather updated: '
      '${updatedWeather.cityName}',
    );
  }

  // ============================================================
  // SELECT CITY BY INDEX
  // ============================================================

  void selectCityByIndex(int index) {
    if (index < 0 || index >= _savedCities.length) {
      return;
    }

    _currentCityIndex = index;

    _weatherData = _savedCities[index];

    _errorMessage = null;
    _showLocationInitialError = false;
    _showLocationRefreshError = false;

    _updateBackgroundImage(_weatherData!);

    debugPrint(
      '🔄 Active city changed: '
      '${_weatherData!.cityName}',
    );

    notifyListeners();
  }

  // ============================================================
  // CURRENT CITY
  // ============================================================

  WeatherDetailModel? get currentCityWeather {
    if (_currentCityIndex < 0 || _currentCityIndex >= _savedCities.length) {
      return _weatherData;
    }

    return _savedCities[_currentCityIndex];
  }

  // ============================================================
  // REMOVE CITY
  // ============================================================

  Future<void> removeCity(int index) async {
    if (index < 0 || index >= _savedCities.length) {
      return;
    }

    final removedCity = _savedCities[index];

    final wasActive = index == _currentCityIndex;

    debugPrint(
      '🗑️ Removing city: '
      '${removedCity.cityName}',
    );

    await HiveService.removeSavedCity(removedCity);

    _savedCities.removeAt(index);

    if (_savedCities.isEmpty) {
      _currentCityIndex = 0;
      _weatherData = null;

      _backgroundImage = 'assets/images/Gemini_Generated_Image_.png';

      await HiveService.clearWeather();

      notifyListeners();

      return;
    }

    if (index < _currentCityIndex) {
      _currentCityIndex--;
    } else if (wasActive) {
      if (_currentCityIndex >= _savedCities.length) {
        _currentCityIndex = _savedCities.length - 1;
      }
    }

    if (_currentCityIndex < 0) {
      _currentCityIndex = 0;
    }

    if (_currentCityIndex >= _savedCities.length) {
      _currentCityIndex = _savedCities.length - 1;
    }

    _weatherData = _savedCities[_currentCityIndex];

    _updateBackgroundImage(_weatherData!);

    await HiveService.saveWeather(_weatherData!);

    debugPrint('✅ City removed successfully.');

    debugPrint(
      '🏙️ New active city: '
      '${_weatherData!.cityName}',
    );

    debugPrint(
      '📦 Remaining cities: '
      '${_savedCities.length}',
    );

    notifyListeners();
  }

  // ============================================================
  // LOAD CACHE
  //
  // Hive already stores savedCities in persistent order.
  // Therefore the list loaded here is the same order that
  // the user created before closing the app.
  // ============================================================

  void _loadCachedWeather() {
    try {
      final savedCities = HiveService.getSavedCities();

      if (savedCities.isNotEmpty) {
        _savedCities
          ..clear()
          ..addAll(savedCities);

        _currentCityIndex = 0;

        _weatherData = _savedCities[_currentCityIndex];

        debugPrint(
          '📦 Loaded ${_savedCities.length} '
          'saved cities from Hive.',
        );

        debugPrint(
          '🏙️ Active cached city: '
          '${_weatherData!.cityName}',
        );

        debugPrint(
          '🔀 Saved order: '
          '${_savedCities.map((city) => city.cityName).join(' → ')}',
        );

        _updateBackgroundImage(_weatherData!);

        notifyListeners();

        return;
      }

      final cachedWeather = HiveService.getWeather();

      if (cachedWeather != null) {
        _weatherData = cachedWeather;
        _currentCityIndex = 0;

        debugPrint(
          '📦 Latest cached weather loaded: '
          '${cachedWeather.cityName}',
        );

        _updateBackgroundImage(cachedWeather);

        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading cached weather: $e');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // WEATHER UPDATE TIMER
  // ============================================================

  void _startWeatherUpdateTimer() {
    _weatherUpdateTimer?.cancel();

    _weatherUpdateTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (_isAppInForeground) {
        _refreshWeatherAutomatically();
      }
    });
  }

  Future<void> _refreshWeatherAutomatically() async {
    if (_isLoading) {
      return;
    }

    debugPrint('⏱️ Automatic weather update started...');

    await refreshWeather();

    debugPrint('✅ Automatic weather update finished.');
  }

  bool _isAppInForeground = true;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;

      debugPrint('▶️ App resumed.');

      _startWeatherUpdateTimer();

      _refreshWeatherAutomatically();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _isAppInForeground = false;

      debugPrint('⏸️ App paused. Weather timer stopped.');

      _weatherUpdateTimer?.cancel();
      _weatherUpdateTimer = null;
    }
  }

  // ============================================================
  // BACKGROUND TIMER
  // ============================================================

  void _startBackgroundTimer() {
    _backgroundTimer?.cancel();

    _backgroundTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateBackgroundFromCurrentTime();
    });
  }

  void _updateBackgroundFromCurrentTime() {
    final weather = _weatherData;

    if (weather == null) {
      return;
    }

    try {
      final condition = weather.weatherMain.trim().toLowerCase();

      final normalizedCondition = condition.isNotEmpty ? condition : 'clear';

      final newBackgroundImage = WeatherController.getBackgroundImage(
        normalizedCondition,
        weather.sunrise,
        weather.sunset,
      );

      if (newBackgroundImage == _backgroundImage) {
        return;
      }

      _backgroundImage = newBackgroundImage;

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Background timer error: $e');
    }
  }

  void _updateBackgroundImage(WeatherDetailModel weather) {
    try {
      final condition = weather.weatherMain.trim().toLowerCase();

      final normalizedCondition = condition.isNotEmpty ? condition : 'clear';

      _backgroundImage = WeatherController.getBackgroundImage(
        normalizedCondition,
        weather.sunrise,
        weather.sunset,
      );
    } catch (e) {
      debugPrint('❌ Background error: $e');

      _backgroundImage = 'assets/images/Gemini_Generated_Image_.png';
    }
  }

  // ============================================================
  // LOCATION MESSAGES
  // ============================================================

  void dismissLocationMessage() {
    _showLocationInitialError = false;
    _showLocationRefreshError = false;
    _errorMessage = null;

    notifyListeners();
  }

  Future<bool> openLocationSettings() async {
    return await _locationService.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    return await _locationService.openAppSettings();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _backgroundTimer?.cancel();
    _backgroundTimer = null;

    _weatherUpdateTimer?.cancel();
    _weatherUpdateTimer = null;

    super.dispose();
  }
}
