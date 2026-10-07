import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive.dart';
import '../../controllers/weather_provider.dart';
import '../../data/models/weather_detail_model.dart';
import '../../data/repositories/weather_repository.dart';

class SearchCityPage extends StatefulWidget {
  const SearchCityPage({super.key});

  @override
  State<SearchCityPage> createState() => _SearchCityPageState();
}

class _SearchCityPageState extends State<SearchCityPage> {
  final TextEditingController _searchController = TextEditingController();

  final WeatherRepository _weatherRepository = WeatherRepository();

  Timer? _debounceTimer;

  List<CityGeoModel> _cities = [];

  final Map<String, WeatherDetailModel?> _weatherResults = {};

  final Set<String> _addingCities = {};

  final Set<String> _removingCities = {};

  bool _isSearching = false;

  String _lastSearchText = '';

  int _searchRequestId = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // DISPLAY CITY NAME
  // ============================================================

  String _displayCityName(CityGeoModel city) {
 
    if (city.name.trim().isNotEmpty) {
      return city.name.trim();
    }

    if (city.nameFa != null && city.nameFa!.trim().isNotEmpty) {
      return city.nameFa!.trim();
    }

    if (city.nameEn != null && city.nameEn!.trim().isNotEmpty) {
      return city.nameEn!.trim();
    }

    return 'Unknown';
  }

  // ============================================================
  // DISPLAY CITY ENGLISH NAME
  // ============================================================

  String _displayCityEnglishName(CityGeoModel city) {
    if (city.nameEn != null && city.nameEn!.trim().isNotEmpty) {
      return city.nameEn!.trim();
    }

    if (city.name.isNotEmpty) {
      return city.name.trim();
    }

    return '';
  }

  // ============================================================
  // DISPLAY SAVED CITY ENGLISH NAME
  // ============================================================

  String _displaySavedCityEnglishName(WeatherDetailModel city) {
    if (city.cityNameEn != null && city.cityNameEn!.trim().isNotEmpty) {
      return city.cityNameEn!.trim();
    }

    if (city.cityName.isNotEmpty) {
      return city.cityName.trim();
    }

    return '';
  }

  // ============================================================
  // CREATE DISPLAY CITY
  // ============================================================

  CityGeoModel _createDisplayCity(CityGeoModel city) {
    return CityGeoModel(
   
      name: _displayCityName(city),
      nameFa: city.nameFa,
      nameEn: city.nameEn ?? city.name,
      lat: city.lat,
      lon: city.lon,
      country: city.country,
      state: city.state,
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    
    _searchRequestId++;

    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _cities = [];
        _weatherResults.clear();
        _isSearching = false;
        _lastSearchText = '';
      });

      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _searchCities(query, _searchRequestId);
    });
  }

  // ============================================================
  // SEARCH CITIES
  // ============================================================

  Future<void> _searchCities(String query, int requestId) async {
    if (!mounted) {
      return;
    }

   
    if (requestId != _searchRequestId) {
      return;
    }

    setState(() {
      _isSearching = true;
      _lastSearchText = query;
      _cities = [];
      _weatherResults.clear();
    });

    try {
      final cities = await _weatherRepository.searchCities(query);

      if (!mounted) {
        return;
      }

      
      if (requestId != _searchRequestId) {
        return;
      }

      if (query != _lastSearchText) {
        return;
      }

      setState(() {
        _cities = cities;
      });

      await Future.wait(
        cities.map((city) => _loadWeatherForCity(city, requestId)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _cities = [];
      });
    } finally {
      if (!mounted) {
        return;
      }

      if (requestId != _searchRequestId) {
        return;
      }

      if (query != _lastSearchText) {
        return;
      }

      setState(() {
        _isSearching = false;
      });
    }
  }

  // ============================================================
  // LOAD WEATHER FOR SEARCH RESULT
  // ============================================================

  Future<void> _loadWeatherForCity(CityGeoModel city, int requestId) async {
    try {
      final weather = await _weatherRepository.getWeatherDetails(
        city.lat,
        city.lon,

        
        reverseGeocode: false,
      );

      if (!mounted) {
        return;
      }

     
      if (requestId != _searchRequestId) {
        return;
      }

      if (_lastSearchText.isEmpty) {
        return;
      }

      final key = _cityKey(city);

      setState(() {
        _weatherResults[key] = weather;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (requestId != _searchRequestId) {
        return;
      }

      final key = _cityKey(city);

      setState(() {
        _weatherResults[key] = null;
      });
    }
  }

  // ============================================================
  // SELECT CITY
  // ============================================================

  Future<void> _selectCity(CityGeoModel city) async {
    final provider = context.read<WeatherProvider>();

    
    final displayCity = _createDisplayCity(city);

    final success = await provider.selectCity(displayCity);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
    }
  }

  // ============================================================
  // ADD CITY
  // ============================================================

  Future<void> _addCity(CityGeoModel city) async {
    final provider = context.read<WeatherProvider>();

    final key = _cityKey(city);

    if (_addingCities.contains(key)) {
      return;
    }

    if (_isCitySaved(provider, city)) {
      return;
    }

    setState(() {
      _addingCities.add(key);
    });

    try {
      final displayCity = _createDisplayCity(city);

      final success = await provider.addCity(
        displayCity,
        weather: _weatherResults[key],
      );

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${_displayCityName(city)} was added to saved cities.',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          );
      } else {
        final error = provider.errorMessage;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to add the city.'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _addingCities.remove(key);
        });
      }
    }
  }

  // ============================================================
  // REMOVE SAVED CITY
  // ============================================================

  Future<void> _removeSavedCity(
    WeatherProvider provider,
    WeatherDetailModel city,
  ) async {
    final cityKey = _savedCityKey(city);

    final index = provider.savedCities.indexWhere(
      (savedCity) => _savedCityKey(savedCity) == cityKey,
    );

    if (index < 0 || index >= provider.savedCities.length) {
      return;
    }

    if (_removingCities.contains(cityKey)) {
      return;
    }

    setState(() {
      _removingCities.add(cityKey);
    });

    try {
      await provider.removeCity(index);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${city.cityName} was removed from saved cities.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _removingCities.remove(cityKey);
        });
      }
    }
  }

  // ============================================================
  // CITY KEY
  // ============================================================

  String _cityKey(CityGeoModel city) {
    return '${city.name}_${city.lat}_${city.lon}';
  }

  String _savedCityKey(WeatherDetailModel city) {
    return '${city.cityName}_'
        '${city.latitude}_'
        '${city.longitude}';
  }

  // ============================================================
  // IS CITY SAVED?
  // ============================================================

  bool _isCitySaved(WeatherProvider provider, CityGeoModel city) {
    for (final savedCity in provider.savedCities) {
      final latDifference = (savedCity.latitude - city.lat).abs();

      final lonDifference = (savedCity.longitude - city.lon).abs();

      if (latDifference < 0.001 && lonDifference < 0.001) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // LOCATION NAME
  // ============================================================

  String _buildLocationName(CityGeoModel city) {
    final parts = <String>[];

    final englishName = _displayCityEnglishName(city);

    if (englishName.isNotEmpty && englishName != _displayCityName(city)) {
      parts.add(englishName);
    }

    if (city.state != null && city.state!.trim().isNotEmpty) {
      parts.add(city.state!.trim());
    }

    if (city.country != null && city.country!.trim().isNotEmpty) {
      parts.add(city.country!.trim());
    }

    return parts.join(' · ');
  }

  // ============================================================
  // SAVED LOCATION NAME
  // ============================================================

  String _buildSavedLocationName(WeatherDetailModel city) {
    final parts = <String>[];

    final englishName = _displaySavedCityEnglishName(city);

    if (englishName.isNotEmpty && englishName != city.cityName.trim()) {
      parts.add(englishName);
    }

    if (city.state != null && city.state!.trim().isNotEmpty) {
      parts.add(city.state!.trim());
    }

    if (city.country != null && city.country!.trim().isNotEmpty) {
      parts.add(city.country!.trim());
    }

    return parts.join(' · ');
  }

  // ============================================================
  // WEATHER TYPE
  // ============================================================

  String _getWeatherType(WeatherDetailModel? weather) {
    if (weather == null) {
      return 'unknown';
    }

    final main = weather.weatherMain.trim().toLowerCase();

    final description = weather.weatherDescription.trim().toLowerCase();

    final value = '$main $description';

    if (value.contains('thunder') ||
        value.contains('storm') ||
        value.contains('رعد') ||
        value.contains('برق') ||
        value.contains('طوفان')) {
      return 'storm';
    }

    if (value.contains('snow') ||
        value.contains('sleet') ||
        value.contains('برف')) {
      return 'snow';
    }

    if (value.contains('rain') ||
        value.contains('shower') ||
        value.contains('باران') ||
        value.contains('رگبار')) {
      return 'rain';
    }

    if (value.contains('drizzle') ||
        value.contains('نم نم') ||
        value.contains('نم‌نم')) {
      return 'drizzle';
    }

    if (value.contains('fog') ||
        value.contains('mist') ||
        value.contains('haze') ||
        value.contains('مه')) {
      return 'fog';
    }

    if (value.contains('wind') ||
        value.contains('breeze') ||
        value.contains('باد')) {
      return 'wind';
    }

    if (value.contains('partly') ||
        value.contains('partly cloudy') ||
        value.contains('نیمه ابری') ||
        value.contains('نیمه‌ابری')) {
      return _isNight(weather) ? 'partlyCloudyNight' : 'partlyCloudy';
    }

    if (value.contains('cloud') ||
        value.contains('overcast') ||
        value.contains('ابری')) {
      return _isNight(weather) ? 'cloudyNight' : 'cloudy';
    }

    if (value.contains('clear') ||
        value.contains('sunny') ||
        value.contains('آفتابی') ||
        value.contains('صاف')) {
      return _isNight(weather) ? 'clearNight' : 'sunny';
    }

    return 'unknown';
  }

  // ============================================================
  // NIGHT DETECTION
  // ============================================================

  bool _isNight(WeatherDetailModel weather) {
    final sunrise = weather.sunrise;
    final sunset = weather.sunset;

    if (sunrise <= 0 || sunset <= 0 || sunset <= sunrise) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return now < sunrise || now >= sunset;
  }

  // ============================================================
  // WEATHER ICON
  // ============================================================

  Widget _buildWeatherIcon(WeatherDetailModel? weather) {
    final type = _getWeatherType(weather);

    Widget icon;

    switch (type) {
      case 'sunny':
        icon = const _SunnyWeatherIcon();

      case 'clearNight':
        icon = const _ClearNightWeatherIcon();

      case 'partlyCloudy':
        icon = const _PartlyCloudyWeatherIcon();

      case 'partlyCloudyNight':
        icon = const _PartlyCloudyNightWeatherIcon();

      case 'rain':
        icon = const _RainWeatherIcon();

      case 'drizzle':
        icon = const _DrizzleWeatherIcon();

      case 'storm':
        icon = const _StormWeatherIcon();

      case 'snow':
        icon = const _SnowWeatherIcon();

      case 'fog':
        icon = const _FogWeatherIcon();

      case 'wind':
        icon = const _WindWeatherIcon();

      case 'cloudy':
        icon = const _CloudyWeatherIcon();

      case 'cloudyNight':
        icon = const _CloudyNightWeatherIcon();

      default:
        icon = const _UnknownWeatherIcon();
    }

    return Container(
      width: Responsive.scale(context, 52),
      height: Responsive.scale(context, 52),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: Responsive.scale(context, 1),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: Responsive.scale(context, 38),
          height: Responsive.scale(context, 38),
          child: icon,
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH RESULTS
  // ============================================================

  Widget _buildSearchResults() {
    if (_isSearching && _cities.isEmpty) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: Responsive.scale(context, 2),
          ),
        ),
      );
    }

    if (_lastSearchText.isEmpty) {
      return _buildSavedCities();
    }

    if (_cities.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No cities found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: Responsive.scale(context, 15),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: EdgeInsets.only(
          top: Responsive.scale(context, 20),
          bottom: Responsive.scale(context, 24),
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: _cities.length,
        separatorBuilder: (_, __) =>
            SizedBox(height: Responsive.scale(context, 12)),
        itemBuilder: (context, index) {
          return _buildCityCard(_cities[index]);
        },
      ),
    );
  }

  // ============================================================
  // SAVED CITIES
  //
  // Provider's savedCities is already persistent and ordered.
  // ============================================================

  Widget _buildSavedCities() {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        final savedCities = provider.savedCities;

        if (savedCities.isEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                'Search for a city',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: Responsive.scale(context, 15),
                ),
              ),
            ),
          );
        }

        return Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.only(
              top: Responsive.scale(context, 20),
              bottom: Responsive.scale(context, 24),
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: savedCities.length,
            buildDefaultDragHandles: false,

            // Prevents Flutter's default Material proxy
            // from creating the white halo around the glass card.
            proxyDecorator: (child, index, animation) {
              return child;
            },

            onReorderItem: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }

              if (oldIndex < 0 ||
                  oldIndex >= savedCities.length ||
                  newIndex < 0 ||
                  newIndex >= savedCities.length) {
                return;
              }

              await provider.reorderSavedCities(oldIndex, newIndex);
            },

            itemBuilder: (context, index) {
              final city = savedCities[index];

              return Padding(
                key: ValueKey(_savedCityKey(city)),
                padding: EdgeInsets.only(bottom: Responsive.scale(context, 12)),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: _buildSavedCityCard(provider, city, index),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // SAVED CITY CARD
  // ============================================================

  Widget _buildSavedCityCard(
    WeatherProvider provider,
    WeatherDetailModel city,
    int index,
  ) {
    final cityKey = _savedCityKey(city);

    final isRemoving = _removingCities.contains(cityKey);

    final englishName = _displaySavedCityEnglishName(city);

    return _buildGlassCard(
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isRemoving
                    ? null
                    : () {
                        final providerIndex = provider.savedCities.indexWhere(
                          (savedCity) => _savedCityKey(savedCity) == cityKey,
                        );

                        if (providerIndex < 0) {
                          return;
                        }

                        Navigator.of(context).pop();

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) {
                            return;
                          }

                          provider.selectCityByIndex(providerIndex);
                        });
                      },
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Responsive.scale(context, 24)),
                  bottomLeft: Radius.circular(Responsive.scale(context, 24)),
                ),
                splashColor: Colors.white.withValues(alpha: 0.08),
                highlightColor: Colors.white.withValues(alpha: 0.04),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: Responsive.scale(context, 18),
                    top: Responsive.scale(context, 18),
                    bottom: Responsive.scale(context, 18),
                    right: Responsive.scale(context, 8),
                  ),
                  child: Row(
                    children: [
                      _buildWeatherIcon(city),
                      SizedBox(width: Responsive.scale(context, 14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city.cityName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.scale(context, 19),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: Responsive.scale(context, 4)),
                            if (englishName.isNotEmpty)
                              Text(
                                englishName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontSize: Responsive.scale(context, 13.5),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            if (englishName.isNotEmpty)
                              SizedBox(height: Responsive.scale(context, 3)),
                            Text(
                              _buildSavedLocationName(city),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: Responsive.scale(context, 13),
                              ),
                            ),
                            SizedBox(height: Responsive.scale(context, 12)),
                            Text(
                              city.weatherDescription.isNotEmpty
                                  ? city.weatherDescription
                                  : 'Weather available',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: Responsive.scale(context, 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: Responsive.scale(context, 8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${city.temp.round()}°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.scale(context, 31),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: Responsive.scale(context, 8)),
                Text(
                  city.forecast.isNotEmpty
                      ? '${city.forecast.first.maxTemp.round()}° / '
                            '${city.forecast.first.minTemp.round()}°'
                      : '--° / --°',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: Responsive.scale(context, 13),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: Responsive.scale(context, 4),
              right: Responsive.scale(context, 10),
            ),
            child: SizedBox(
              width: Responsive.scale(context, 46),
              height: Responsive.scale(context, 46),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isRemoving
                      ? null
                      : () {
                          _removeSavedCity(provider, city);
                        },
                  borderRadius: BorderRadius.circular(
                    Responsive.scale(context, 23),
                  ),
                  child: Center(
                    child: isRemoving
                        ? SizedBox(
                            width: Responsive.scale(context, 20),
                            height: Responsive.scale(context, 20),
                            child: CircularProgressIndicator(
                              strokeWidth: Responsive.scale(context, 2),
                              color: Colors.white70,
                            ),
                          )
                        : Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white.withValues(alpha: 0.80),
                            size: Responsive.scale(context, 25),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH CITY CARD
  // ============================================================

  Widget _buildCityCard(CityGeoModel city) {
    final weather = _weatherResults[_cityKey(city)];

    final provider = context.watch<WeatherProvider>();

    final isSaved = _isCitySaved(provider, city);

    final isAdding = _addingCities.contains(_cityKey(city));

    final temperature = weather?.temp;

    final description = weather?.weatherDescription;

    double? minTemp;
    double? maxTemp;

    if (weather != null && weather.forecast.isNotEmpty) {
      minTemp = weather.forecast.first.minTemp;

      maxTemp = weather.forecast.first.maxTemp;
    }

    final displayName = _displayCityName(city);

    final englishName = _displayCityEnglishName(city);

    return _buildGlassCard(
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectCity(city),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Responsive.scale(context, 24)),
                  bottomLeft: Radius.circular(Responsive.scale(context, 24)),
                ),
                splashColor: Colors.white.withValues(alpha: 0.08),
                highlightColor: Colors.white.withValues(alpha: 0.04),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: Responsive.scale(context, 18),
                    top: Responsive.scale(context, 18),
                    bottom: Responsive.scale(context, 18),
                    right: Responsive.scale(context, 8),
                  ),
                  child: Row(
                    children: [
                      _buildWeatherIcon(weather),
                      SizedBox(width: Responsive.scale(context, 14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.scale(context, 19),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (englishName.isNotEmpty &&
                                englishName != displayName)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: Responsive.scale(context, 4),
                                ),
                                child: Text(
                                  englishName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.68),
                                    fontSize: Responsive.scale(context, 13.5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            SizedBox(height: Responsive.scale(context, 4)),
                            Text(
                              _buildLocationName(city),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: Responsive.scale(context, 13),
                              ),
                            ),
                            SizedBox(height: Responsive.scale(context, 12)),
                            Text(
                              description ?? 'Loading weather...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: Responsive.scale(context, 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: Responsive.scale(context, 8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  temperature != null ? '${temperature.round()}°' : '--°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.scale(context, 31),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: Responsive.scale(context, 8)),
                Text(
                  maxTemp != null && minTemp != null
                      ? '${maxTemp.round()}° / '
                            '${minTemp.round()}°'
                      : '--° / --°',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: Responsive.scale(context, 13),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: Responsive.scale(context, 4),
              right: Responsive.scale(context, 10),
            ),
            child: SizedBox(
              width: Responsive.scale(context, 46),
              height: Responsive.scale(context, 46),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSaved || isAdding ? null : () => _addCity(city),
                  borderRadius: BorderRadius.circular(
                    Responsive.scale(context, 23),
                  ),
                  child: Center(
                    child: isAdding
                        ? SizedBox(
                            width: Responsive.scale(context, 20),
                            height: Responsive.scale(context, 20),
                            child: CircularProgressIndicator(
                              strokeWidth: Responsive.scale(context, 2),
                              color: Colors.white70,
                            ),
                          )
                        : Icon(
                            isSaved ? Icons.check_rounded : Icons.add_rounded,
                            color: isSaved
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.85),
                            size: Responsive.scale(context, isSaved ? 24 : 27),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MATERIAL 3 + LIQUID GLASS CARD
  // ============================================================

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Responsive.scale(context, 24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Material(
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.085),
              borderRadius: BorderRadius.circular(
                Responsive.scale(context, 24),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.17),
                width: Responsive.scale(context, 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: Responsive.scale(context, 22),
                  spreadRadius: Responsive.scale(context, -8),
                  offset: Offset(0, Responsive.scale(context, 8)),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.035),
                  blurRadius: Responsive.scale(context, 1),
                  spreadRadius: 0,
                  offset: Offset(0, Responsive.scale(context, 1)),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Responsive.scale(context, 24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Material(
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: Responsive.scale(context, 58),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.085),
              borderRadius: BorderRadius.circular(
                Responsive.scale(context, 24),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.17),
                width: Responsive.scale(context, 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: Responsive.scale(context, 20),
                  spreadRadius: Responsive.scale(context, -8),
                  offset: Offset(0, Responsive.scale(context, 7)),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.scale(context, 16),
              ),
              cursorColor: Colors.white,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Enter location',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: Responsive.scale(context, 16),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.70),
                  size: Responsive.scale(context, 24),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          _onSearchChanged('');

                          setState(() {});
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.60),
                          size: Responsive.scale(context, 20),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Responsive.scale(context, 16),
                  vertical: Responsive.scale(context, 17),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.scale(context, 20),
            vertical: Responsive.scale(context, 16),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Responsive.scale(context, 18),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Material(
                      color: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(
                          Responsive.scale(context, 18),
                        ),
                        child: Container(
                          width: Responsive.scale(context, 46),
                          height: Responsive.scale(context, 46),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.085),
                            borderRadius: BorderRadius.circular(
                              Responsive.scale(context, 18),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.17),
                              width: Responsive.scale(context, 1),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: Responsive.scale(context, 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Responsive.scale(context, 28)),
              _buildSearchBar(),
              _buildSearchResults(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WEATHER ICONS
// ============================================================

class _SunnyWeatherIcon extends StatelessWidget {
  const _SunnyWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.wb_sunny_rounded,
        color: const Color(0xFFFFD54F),
        size: Responsive.scale(context, 34),
      ),
    );
  }
}

// ============================================================
// FILLED MOON
// ============================================================

class _FilledMoonIcon extends StatelessWidget {
  const _FilledMoonIcon({this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Responsive.scale(context, size),
      height: Responsive.scale(context, size),
      child: CustomPaint(
        painter: const _FilledMoonPainter(color: Color(0xFF2F718A)),
      ),
    );
  }
}

class _FilledMoonPainter extends CustomPainter {
  const _FilledMoonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(size.width * 0.43, size.height * 0.48);

    final radius = size.shortestSide * 0.37;

    final outer = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final cut = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            center.dx + size.width * 0.20,
            center.dy - size.height * 0.14,
          ),
          radius: radius * 0.91,
        ),
      );

    final crescent = Path.combine(PathOperation.difference, outer, cut);

    canvas.drawPath(crescent, paint);
  }

  @override
  bool shouldRepaint(covariant _FilledMoonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ============================================================
// HIGHLIGHT CLOUD
// ============================================================

class _HighlightCloudIcon extends StatelessWidget {
  const _HighlightCloudIcon({this.size = 33});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scaledSize = Responsive.scale(context, size);

    return SizedBox(
      width: scaledSize,
      height: scaledSize * 0.82,
      child: Center(
        child: Icon(
          Icons.cloud_rounded,
          size: scaledSize,
          color: Colors.white.withValues(alpha: 0.68),
        ),
      ),
    );
  }
}

// ============================================================
// CLEAR NIGHT
// ============================================================

class _ClearNightWeatherIcon extends StatelessWidget {
  const _ClearNightWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Center(child: _FilledMoonIcon(size: Responsive.scale(context, 35)));
  }
}

// ============================================================
// PARTLY CLOUDY
// ============================================================

class _PartlyCloudyWeatherIcon extends StatelessWidget {
  const _PartlyCloudyWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          right: Responsive.scale(context, 1),
          child: Icon(
            Icons.wb_sunny_rounded,
            color: const Color(0xFFFFD54F),
            size: Responsive.scale(context, 27),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Icon(
            Icons.cloud_rounded,
            color: Colors.white.withValues(alpha: 0.92),
            size: Responsive.scale(context, 31),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PARTLY CLOUDY NIGHT
// ============================================================

class _PartlyCloudyNightWeatherIcon extends StatelessWidget {
  const _PartlyCloudyNightWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Responsive.scale(context, 38),
      height: Responsive.scale(context, 38),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Center(
              child: _FilledMoonIcon(size: Responsive.scale(context, 34)),
            ),
          ),
          Positioned(
            left: Responsive.scale(context, 1),
            right: Responsive.scale(context, 1),
            bottom: Responsive.scale(context, 1),
            child: Center(
              child: _HighlightCloudIcon(size: Responsive.scale(context, 31)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RAIN
// ============================================================

class _RainWeatherIcon extends StatelessWidget {
  const _RainWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 0,
          left: Responsive.scale(context, 3),
          child: Icon(
            Icons.cloud_rounded,
            color: const Color(0xFFE6EDF5),
            size: Responsive.scale(context, 31),
          ),
        ),
        Positioned(
          bottom: 0,
          left: Responsive.scale(context, 4),
          child: Transform.rotate(
            angle: 0.15,
            child: Icon(
              Icons.water_drop_rounded,
              color: const Color(0xFF42A5F5),
              size: Responsive.scale(context, 13),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: Responsive.scale(context, 5),
          child: Transform.rotate(
            angle: 0.15,
            child: Icon(
              Icons.water_drop_rounded,
              color: const Color(0xFF2196F3),
              size: Responsive.scale(context, 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DRIZZLE
// ============================================================

class _DrizzleWeatherIcon extends StatelessWidget {
  const _DrizzleWeatherIcon();

  @override
  Widget build(BuildContext context) {
    final dotWidth = Responsive.scale(context, 3);

    final dotHeight = Responsive.scale(context, 7);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: Responsive.scale(context, 3),
          child: Icon(
            Icons.cloud_rounded,
            color: const Color(0xFFE3EAF2),
            size: Responsive.scale(context, 31),
          ),
        ),
        Positioned(
          bottom: 0,
          left: Responsive.scale(context, 7),
          child: Container(
            width: dotWidth,
            height: dotHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: Responsive.scale(context, 17),
          child: Container(
            width: dotWidth,
            height: dotHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF90CAF9),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: Responsive.scale(context, 27),
          child: Container(
            width: dotWidth,
            height: dotHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STORM
// ============================================================

class _StormWeatherIcon extends StatelessWidget {
  const _StormWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: Responsive.scale(context, 2),
          child: Icon(
            Icons.cloud_rounded,
            color: const Color(0xFF90A0B2),
            size: Responsive.scale(context, 32),
          ),
        ),
        Positioned(
          bottom: Responsive.scale(context, -1),
          left: Responsive.scale(context, 12),
          child: Transform.rotate(
            angle: 0.08,
            child: Icon(
              Icons.bolt_rounded,
              color: const Color(0xFFFFD740),
              size: Responsive.scale(context, 25),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SNOW
// ============================================================

class _SnowWeatherIcon extends StatelessWidget {
  const _SnowWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: Responsive.scale(context, 3),
          child: Icon(
            Icons.cloud_rounded,
            color: const Color(0xFFE8EEF5),
            size: Responsive.scale(context, 31),
          ),
        ),
        Positioned(
          bottom: Responsive.scale(context, -1),
          left: Responsive.scale(context, 5),
          child: Icon(
            Icons.ac_unit_rounded,
            color: const Color(0xFF81D4FA),
            size: Responsive.scale(context, 12),
          ),
        ),
        Positioned(
          bottom: Responsive.scale(context, -1),
          right: Responsive.scale(context, 5),
          child: Icon(
            Icons.ac_unit_rounded,
            color: const Color(0xFFB3E5FC),
            size: Responsive.scale(context, 12),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FOG
// ============================================================

class _FogWeatherIcon extends StatelessWidget {
  const _FogWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: Responsive.scale(context, 2),
          child: Icon(
            Icons.cloud_rounded,
            color: Colors.white.withValues(alpha: 0.68),
            size: Responsive.scale(context, 29),
          ),
        ),
        Positioned(
          bottom: Responsive.scale(context, 7),
          child: Container(
            width: Responsive.scale(context, 29),
            height: Responsive.scale(context, 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
        ),
        Positioned(
          bottom: Responsive.scale(context, 1),
          child: Container(
            width: Responsive.scale(context, 22),
            height: Responsive.scale(context, 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// WIND
// ============================================================

class _WindWeatherIcon extends StatelessWidget {
  const _WindWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: Responsive.scale(context, 7),
          left: Responsive.scale(context, 3),
          child: Container(
            width: Responsive.scale(context, 25),
            height: Responsive.scale(context, 3),
            decoration: BoxDecoration(
              color: const Color(0xFF90CAF9),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
        ),
        Positioned(
          top: Responsive.scale(context, 15),
          left: Responsive.scale(context, 7),
          child: Container(
            width: Responsive.scale(context, 28),
            height: Responsive.scale(context, 3),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
        ),
        Positioned(
          top: Responsive.scale(context, 23),
          left: Responsive.scale(context, 3),
          child: Container(
            width: Responsive.scale(context, 20),
            height: Responsive.scale(context, 3),
            decoration: BoxDecoration(
              color: const Color(0xFF90CAF9),
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CLOUDY
// ============================================================

class _CloudyWeatherIcon extends StatelessWidget {
  const _CloudyWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.cloud_rounded,
        color: const Color(0xFFDCE4ED),
        size: Responsive.scale(context, 36),
      ),
    );
  }
}

// ============================================================
// CLOUDY NIGHT
// ============================================================

class _CloudyNightWeatherIcon extends StatelessWidget {
  const _CloudyNightWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Responsive.scale(context, 38),
      height: Responsive.scale(context, 38),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Center(
              child: _FilledMoonIcon(size: Responsive.scale(context, 34)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: Responsive.scale(context, 1),
            child: Center(
              child: _HighlightCloudIcon(size: Responsive.scale(context, 34)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// UNKNOWN
// ============================================================

class _UnknownWeatherIcon extends StatelessWidget {
  const _UnknownWeatherIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.cloud_outlined,
        color: const Color(0xFFB0BEC5),
        size: Responsive.scale(context, 34),
      ),
    );
  }
}
