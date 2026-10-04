import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/weather_contoroller.dart';
import '../../controllers/weather_provider.dart';
import '../../data/models/weather_detail_model.dart';
import '../widgets/weather_forecast_content.dart';
import 'search_city_page.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // ============================================================
  // Swipe
  // ============================================================

  double _dragDistance = 0.0;

  bool _isChangingCity = false;

  // -1 = swipe left
  //  1 = swipe right
  int _lastSwipeDirection = 0;

  // ============================================================
  // City Transition
  // ============================================================

  AnimationController? _cityTransitionController;

  WeatherDetailModel? _transitionOldCity;

  WeatherDetailModel? _transitionNewCity;

  // ============================================================
  // Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // ------------------------------------------------------------
    // Lightweight and fast
    // ------------------------------------------------------------

    _cityTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<WeatherProvider>().initializeLocation();
    });
  }

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;

      final provider = context.read<WeatherProvider>();

      provider.checkLocationAfterResume();
    }
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _cityTransitionController?.dispose();
    _cityTransitionController = null;

    super.dispose();
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarColor: Colors.transparent,
          ),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: _buildHomeContent(context, weatherProvider),
          ),
        );
      },
    );
  }

  // ============================================================
  // Home Content
  // ============================================================

  Widget _buildHomeContent(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    if (!weatherProvider.hasData && weatherProvider.isFirstLoad) {
      return _buildLoadingView();
    }

    if (!weatherProvider.hasData) {
      if (weatherProvider.shouldShowLocationError) {
        return _buildLocationMessage(context, weatherProvider);
      }

      if (weatherProvider.shouldShowError) {
        return _buildErrorView(context, weatherProvider);
      }

      return _buildLoadingView();
    }

    if (weatherProvider.savedCities.isEmpty) {
      return _buildSingleWeatherPage(context, weatherProvider.weatherData);
    }

    return _buildCityContent(context, weatherProvider);
  }

  // ============================================================
  // City Content
  // ============================================================

  Widget _buildCityContent(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    final savedCities = weatherProvider.savedCities;

    if (savedCities.isEmpty) {
      return _buildSingleWeatherPage(context, weatherProvider.weatherData);
    }

    final currentIndex = weatherProvider.currentCityIndex
        .clamp(0, savedCities.length - 1)
        .toInt();

    final currentCity = savedCities[currentIndex];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      // ==========================================================
      // Drag Start
      // ==========================================================
      onHorizontalDragStart: (_) {
        if (_isChangingCity) return;

        _dragDistance = 0.0;
      },

      // ==========================================================
      // Drag Update
      // ==========================================================
      onHorizontalDragUpdate: (details) {
        if (_isChangingCity) return;

        _dragDistance += details.delta.dx;
      },

      // ==========================================================
      // Drag End
      // ==========================================================
      onHorizontalDragEnd: (details) {
        if (_isChangingCity) {
          _dragDistance = 0.0;
          return;
        }

        final velocity = details.primaryVelocity ?? 0.0;

        final width = Responsive.width(context);

        final distanceThreshold = width * 0.16;

        const velocityThreshold = 450.0;

        final isSwipeLeft =
            _dragDistance < -distanceThreshold || velocity < -velocityThreshold;

        final isSwipeRight =
            _dragDistance > distanceThreshold || velocity > velocityThreshold;

        _dragDistance = 0.0;

        if (isSwipeLeft) {
          _lastSwipeDirection = -1;

          _changeCity(weatherProvider, currentIndex + 1);
        } else if (isSwipeRight) {
          _lastSwipeDirection = 1;

          _changeCity(weatherProvider, currentIndex - 1);
        }
      },

      child: _buildCityTransition(context, currentCity),
    );
  }

  // ============================================================
  // Cover Slide Transition
  //
  // The previous page remains completely fixed.
  //
  // The new page moves like a layer from the left/right
  // over the previous page.
  // ============================================================

  Widget _buildCityTransition(
    BuildContext context,
    WeatherDetailModel currentCity,
  ) {
    final controller = _cityTransitionController;

    final oldCity = _transitionOldCity;

    final newCity = _transitionNewCity;

    // ============================================================
    // Normal State
    // ============================================================

    if (controller == null ||
        !_isChangingCity ||
        oldCity == null ||
        newCity == null) {
      return _buildWeatherPage(context, currentCity);
    }

    // ============================================================
    // Important:
    //
    // These two Widgets are created outside AnimatedBuilder.
    //
    // Therefore, during each animation frame,
    // the entire Weather Page is not rebuilt.
    //
    // This is important for preventing lag.
    // ============================================================

    final oldPage = RepaintBoundary(child: _buildWeatherPage(context, oldCity));

    final newPage = RepaintBoundary(child: _buildWeatherPage(context, newCity));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final value = controller.value;

            // ====================================================
            // Main Movement
            //
            // easeOutCubic:
            // It starts quickly and smoothly stops at the end.
            // ====================================================

            final progress = Curves.easeOutCubic.transform(value);

            // ====================================================
            // Incoming X
            //
            // The new page starts exactly from the screen edge.
            //
            // Left:
            //   1 → 0
            //
            // Right:
            //  -1 → 0
            // ====================================================

            final direction = _lastSwipeDirection < 0 ? 1.0 : -1.0;

            final incomingX = direction * width * (1.0 - progress);

            // ====================================================
            // Edge Shadow
            // ====================================================

            final shadowOpacity = 0.26 * Curves.easeOut.transform(value);

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                // ==================================================
                // OLD PAGE
                // ==================================================

                oldPage,

                // ==================================================
                // NEW PAGE
                // ==================================================
                Transform.translate(
                  offset: Offset(incomingX, 0),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      newPage,

                      // --------------------------------------------
                      // Leading Edge Shadow
                      // --------------------------------------------
                      IgnorePointer(
                        child: Align(
                          alignment: _lastSwipeDirection < 0
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: SizedBox(
                            width: 22,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: _lastSwipeDirection < 0
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  end: _lastSwipeDirection < 0
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  colors: [
                                    Colors.black.withValues(
                                      alpha: shadowOpacity,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Change City
  // ============================================================

  void _changeCity(WeatherProvider provider, int targetIndex) {
    if (_isChangingCity) return;

    if (targetIndex < 0 || targetIndex >= provider.savedCities.length) {
      return;
    }

    if (targetIndex == provider.currentCityIndex) {
      return;
    }

    final controller = _cityTransitionController;

    if (controller == null) return;

    // ============================================================
    // Current / Target
    // ============================================================

    final currentIndex = provider.currentCityIndex
        .clamp(0, provider.savedCities.length - 1)
        .toInt();

    final oldCity = provider.savedCities[currentIndex];

    final newCity = provider.savedCities[targetIndex];

    // ============================================================
    // Prepare
    // ============================================================

    setState(() {
      _isChangingCity = true;

      _transitionOldCity = oldCity;

      _transitionNewCity = newCity;
    });

    // ============================================================
    // Reset
    // ============================================================

    controller
      ..stop()
      ..value = 0.0;

    // ============================================================
    // Start Animation
    // ============================================================

    controller.forward().then((_) {
      if (!mounted) return;

      // ==========================================================
      // Change Provider After Animation
      // ==========================================================

      provider.selectCityByIndex(targetIndex);

      // ==========================================================
      // Clear Transition
      // ==========================================================

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _isChangingCity = false;

          _transitionOldCity = null;

          _transitionNewCity = null;
        });

        controller.value = 0.0;
      });
    });
  }

  // ============================================================
  // Single Weather Page
  // ============================================================

  Widget _buildSingleWeatherPage(
    BuildContext context,
    WeatherDetailModel? weather,
  ) {
    return _buildWeatherPage(context, weather);
  }

  // ============================================================
  // Weather Page
  // ============================================================

  Widget _buildWeatherPage(BuildContext context, WeatherDetailModel? weather) {
    if (weather == null) {
      return _buildLoadingView();
    }

    final backgroundImage = _getBackgroundImage(weather);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ========================================================
        // Background
        // ========================================================

        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              reverseDuration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder:
                  (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                  child: child,
                );
              },
              child: Image.asset(
                backgroundImage,
                key: ValueKey<String>(backgroundImage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),

        // ========================================================
        // Dark Overlay
        // ========================================================
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.05),
        ),

        // ========================================================
        // Main Content
        // ========================================================
        SafeArea(
          child: RefreshIndicator(
            color: Colors.black87,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await context.read<WeatherProvider>().refreshWeather();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: Responsive.scale(context, 20, min: 0.9, max: 1.1),
                ),

                _buildWeatherInfo(context, weather),

                SizedBox(
                  height: Responsive.scale(context, 320, min: 0.85, max: 1.1),
                ),
              ],
            ),
          ),
        ),

        // ========================================================
        // Forecast
        // ========================================================
        WeatherForecastContent(weatherData: weather),
      ],
    );
  }

  // ============================================================
  // Background Image
  // ============================================================

  String _getBackgroundImage(WeatherDetailModel weather) {
    try {
      // ----------------------------------------------------------
      // IMPORTANT:
      //
      // weatherMain is the normalized weather condition coming
      // from Open-Meteo through WeatherRepository.
      //
      // We must NOT replace a valid condition with "clear".
      // Time of day is handled inside WeatherController.
      // ----------------------------------------------------------

      final weatherMain = _safeText(weather.weatherMain).trim();

      if (weatherMain.isNotEmpty) {
        return WeatherController.getBackgroundImage(
          weatherMain,
          weather.sunrise,
          weather.sunset,
        );
      }

      // ----------------------------------------------------------
      // Fallback:
      //
      // If weatherMain is unexpectedly empty, try the API
      // description instead of immediately assuming Clear.
      // ----------------------------------------------------------

      final description = _safeText(weather.weatherDescription).trim();

      if (description.isNotEmpty) {
        return WeatherController.getBackgroundImage(
          description,
          weather.sunrise,
          weather.sunset,
        );
      }

      // ----------------------------------------------------------
      // Only when absolutely no weather information exists.
      // ----------------------------------------------------------

      return WeatherController.getBackgroundImage(
        'Clear',
        weather.sunrise,
        weather.sunset,
      );
    } catch (_) {
      return 'assets/images/'
          'Gemini_Generated_Image_.png';
    }
  }

  // ============================================================
  // Safe Text
  // ============================================================

  String _safeText(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  // ============================================================
  // Loading
  // ============================================================

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading weather information...',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Error
  // ============================================================

  Widget _buildErrorView(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(Responsive.scale(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: Responsive.scale(context, 60),
                color: Colors.white70,
              ),
              SizedBox(height: Responsive.scale(context, 16)),
              Text(
                _safeText(weatherProvider.errorMessage).isNotEmpty
                    ? _safeText(weatherProvider.errorMessage)
                    : 'An error occurred.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.scale(context, 16),
                  color: Colors.white,
                ),
              ),
              SizedBox(height: Responsive.scale(context, 20)),
              FilledButton(
                onPressed: () {
                  context.read<WeatherProvider>().initializeLocation();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Weather Info
  // ============================================================

  Widget _buildWeatherInfo(BuildContext context, WeatherDetailModel weather) {
    double? todayMinTemp;
    double? todayMaxTemp;

    if (weather.forecast.isNotEmpty) {
      final todayForecast = weather.forecast.first;

      todayMinTemp = todayForecast.minTemp;

      todayMaxTemp = todayForecast.maxTemp;
    }

    // ==========================================================
    // City Name
    //
    // IMPORTANT:
    //
    // weather.cityName is already selected according to the
    // language used during city search.
    //
    // Persian search:
    //   city.name = Persian name
    //
    // English search:
    //   city.name = English name
    //
    // Therefore we should display cityName directly instead of
    // showing Persian + English together.
    // ==========================================================

    final displayCityName = _safeText(weather.cityName).trim();

    final weatherDescription = _safeText(weather.weatherDescription);

    final hasTodayTemperature = todayMinTemp != null && todayMaxTemp != null;

    final hasDescription = weatherDescription.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: Responsive.scale(context, 170, min: 0.9, max: 1.1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ======================================================
          // City
          // ======================================================

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                displayCityName.isNotEmpty ? displayCityName : 'Unknown',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.scale(context, 22),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black26,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // Temperature
          // ======================================================
          Positioned(
            top: Responsive.scale(context, 25),
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${weather.temp.round()}°',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.scale(context, 52),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black26,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // Description + Min / Max
          // ======================================================
          if (hasDescription || hasTodayTemperature)
            Positioned(
              top: Responsive.scale(context, 85),
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDescription)
                      Text(
                        weatherDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.scale(context, 14),
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black26,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    if (hasDescription && hasTodayTemperature)
                      SizedBox(width: Responsive.scale(context, 8)),
                    if (hasTodayTemperature)
                      Text(
                        _formatMinMaxTemperature(todayMaxTemp, todayMinTemp),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.scale(context, 14),
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black26,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // ======================================================
          // Search City
          // ======================================================
          Positioned(
            top: -Responsive.scale(context, 5),
            left: Responsive.scale(context, 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 220),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 160,
                      ),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return const SearchCityPage();
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                                reverseCurve: Curves.easeIn,
                              ),
                              child: child,
                            );
                          },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(
                  Responsive.scale(context, 30),
                ),
                child: SizedBox(
                  width: Responsive.scale(context, 42),
                  height: Responsive.scale(context, 42),
                  child: Center(
                    child: Icon(
                      Icons.my_library_add_outlined,
                      size: Responsive.scale(context, 35),
                      color: Colors.white,
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
  // Min / Max
  // ============================================================

  String _formatMinMaxTemperature(double? maxTemp, double? minTemp) {
    if (maxTemp == null || minTemp == null) {
      return '';
    }

    return '${maxTemp.round()}° / '
        '${minTemp.round()}°';
  }

  // ============================================================
  // Location Message
  // ============================================================

  Widget _buildLocationMessage(
    BuildContext context,
    WeatherProvider weatherProvider,
  ) {
    final errorMessage = _safeText(weatherProvider.errorMessage);

    final hasPreviousWeather = weatherProvider.weatherData != null;

    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(Responsive.scale(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: Responsive.scale(context, 60),
                color: Colors.white70,
              ),
              SizedBox(height: Responsive.scale(context, 16)),
              Text(
                errorMessage.isNotEmpty
                    ? errorMessage
                    : 'To receive weather information, '
                          'please turn on your phone location.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.scale(context, 16),
                  color: Colors.white,
                ),
              ),
              SizedBox(height: Responsive.scale(context, 20)),
              FilledButton.icon(
                onPressed: () async {
                  await context.read<WeatherProvider>().openLocationSettings();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: Colors.white38, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.scale(context, 20),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.scale(context, 24),
                    vertical: Responsive.scale(context, 12),
                  ),
                ),
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: Text(
                  'Enable Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.scale(context, 15),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (hasPreviousWeather) ...[
                SizedBox(height: Responsive.scale(context, 12)),
                TextButton(
                  onPressed: () {
                    context.read<WeatherProvider>().dismissLocationMessage();
                  },
                  child: const Text(
                    'Show Previous Information',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
