import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../weather/controllers/weather_provider.dart';
import '../../../weather/data/models/weather_detail_model.dart';
import '../pages/forecast_details_page.dart';
import '../../presentation/widgets/details_city .dart';

class WeatherForecastContent extends StatelessWidget {
  final WeatherDetailModel? weatherData;

  const WeatherForecastContent({super.key, this.weatherData});

  // ============================================================
  // More Details → WeatherDetailsGrid
  // ============================================================

  void _navigateToWeatherDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const WeatherDetailsGrid();
        },
      ),
    );
  }

  // ============================================================
  // 5-Day Forecast → ForecastDetailsPage
  // ============================================================

  void _navigateToForecastDetails(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const ForecastDetailsPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.ease,
          );

          final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // Provider is kept only for rebuilds and compatibility with
    // the previous structure.
    // ------------------------------------------------------------

    final weatherProvider = Provider.of<WeatherProvider>(context);

    // ------------------------------------------------------------
    // If Weather was passed from the Page, use that data.
    //
    // This is the most important change.
    //
    // Each Forecast Page has its own weather data.
    // ------------------------------------------------------------

    final currentWeather = weatherData ?? weatherProvider.weatherData;

    final forecastList = [...(currentWeather?.forecast ?? [])];

    // ------------------------------------------------------------
    // Sort by the actual API date
    // ------------------------------------------------------------

    forecastList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.dateTxt);

        final dateB = DateTime.parse(b.dateTxt);

        return dateA.compareTo(dateB);
      } catch (_) {
        return 0;
      }
    });

    // ------------------------------------------------------------
    // Only the first 3 days
    // ------------------------------------------------------------

    final threeDaysForecast = forecastList.take(3).toList();

    return Positioned(
      left: Responsive.scale(context, 10, min: 0.9, max: 1.1),
      right: Responsive.scale(context, 10, min: 0.9, max: 1.1),
      bottom: Responsive.scale(context, 8, min: 0.9, max: 1.1),
      height: Responsive.scale(context, 220, min: 0.9, max: 1.1),
      child: AppGlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // Header
            // --------------------------------------------------

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: Colors.white70,
                      size: Responsive.scale(context, 16, min: 0.9, max: 1.1),
                    ),
                    SizedBox(
                      width: Responsive.scale(context, 8, min: 0.9, max: 1.1),
                    ),
                    Text(
                      '3-day forecast',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.scale(
                          context,
                          15,
                          min: 0.9,
                          max: 1.1,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // ------------------------------------------------
                // More details
                // ------------------------------------------------
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _navigateToWeatherDetails(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.scale(
                        context,
                        8,
                        min: 0.9,
                        max: 1.1,
                      ),
                      vertical: Responsive.scale(
                        context,
                        6,
                        min: 0.9,
                        max: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.scale(
                              context,
                              13,
                              min: 0.9,
                              max: 1.1,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          width: Responsive.scale(
                            context,
                            6,
                            min: 0.9,
                            max: 1.1,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white38,
                          size: Responsive.scale(
                            context,
                            11,
                            min: 0.9,
                            max: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Divider(
              color: Colors.white24,
              height: Responsive.scale(context, 16, min: 0.9, max: 1.1),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: Responsive.scale(context, 8, min: 0.9, max: 1.1),
                  ),

                  if (threeDaysForecast.isNotEmpty)
                    ...threeDaysForecast.map((forecast) {
                      final minTemp = forecast.minTemp;

                      final maxTemp = forecast.maxTemp;

                      final progress = _calculateProgress(minTemp, maxTemp);

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.scale(
                            context,
                            4,
                            min: 0.9,
                            max: 1.1,
                          ),
                        ),
                        child: ForecastRowItem(
                          day: _formatDateLabel(forecast.dateTxt),
                          tempMin: '${minTemp.round()}°',
                          tempMax: '${maxTemp.round()}°',
                          progressValue: progress,
                          maxTemp: maxTemp,
                          condition: forecast.condition,
                        ),
                      );
                    })
                  else
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: Responsive.scale(
                            context,
                            2,
                            min: 0.9,
                            max: 1.1,
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // ------------------------------------------------
                  // 6-Day Forecast
                  // ------------------------------------------------
                  Container(
                    width: double.infinity,
                    height: Responsive.scale(context, 38, min: 0.9, max: 1.1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        Responsive.scale(context, 12, min: 0.9, max: 1.1),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          Responsive.scale(context, 12, min: 0.9, max: 1.1),
                        ),
                        onTap: () {
                          _navigateToForecastDetails(context);
                        },
                        child: Center(
                          child: Text(
                            '6-Day Forecast',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.scale(
                                context,
                                14,
                                min: 0.9,
                                max: 1.1,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: Responsive.scale(context, 2, min: 0.9, max: 1.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Progress
  // ============================================================

  double _calculateProgress(double minTemp, double maxTemp) {
    const double minimumTemperature = -10;
    const double maximumTemperature = 45;

    final value =
        (maxTemp - minimumTemperature) /
        (maximumTemperature - minimumTemperature);

    return value.clamp(0.1, 1.0);
  }

  // ============================================================
  // Date
  // ============================================================

  String _formatDateLabel(String dateTxt) {
    try {
      if (dateTxt.isEmpty) {
        return 'Day';
      }

      final dateTime = DateTime.parse(dateTxt);

      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      final difference = targetDate.difference(today).inDays;

      if (difference == 0) {
        return 'Today';
      }

      if (difference == 1) {
        return 'Tomorrow';
      }

      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      return weekdays[dateTime.weekday - 1];
    } catch (_) {
      return 'Day';
    }
  }
}

// ============================================================
// Forecast Row
// ============================================================

class ForecastRowItem extends StatelessWidget {
  final String day;
  final String tempMin;
  final String tempMax;
  final double progressValue;
  final double maxTemp;
  final String condition;

  const ForecastRowItem({
    super.key,
    required this.day,
    required this.tempMin,
    required this.tempMax,
    required this.progressValue,
    required this.maxTemp,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    final weatherIconData = _getWeatherIcon(condition);

    return Row(
      children: [
        SizedBox(
          width: Responsive.scale(context, 80, min: 0.85, max: 1.1),
          child: Text(
            day,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 14, min: 0.9, max: 1.1),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        SizedBox(
          width: Responsive.scale(context, 25, min: 0.9, max: 1.1),
          child: Icon(
            weatherIconData.icon,
            color: weatherIconData.color,
            size: Responsive.scale(context, 20, min: 0.85, max: 1.1),
          ),
        ),

        SizedBox(width: Responsive.scale(context, 8, min: 0.9, max: 1.1)),

        SizedBox(
          width: Responsive.scale(context, 35, min: 0.9, max: 1.1),
          child: Text(
            tempMin,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: Responsive.scale(context, 14, min: 0.9, max: 1.1),
            ),
          ),
        ),

        SizedBox(width: Responsive.scale(context, 6, min: 0.9, max: 1.1)),

        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Responsive.scale(context, 4, min: 0.9, max: 1.1),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Colors.lightBlueAccent,
                    Colors.amber,
                    Colors.deepOrange,
                    Colors.redAccent,
                  ],
                  stops: [0.0, 0.35, 0.7, 1.0],
                  tileMode: TileMode.clamp,
                ).createShader(bounds);
              },
              child: LinearProgressIndicator(
                value: progressValue.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: Responsive.scale(context, 4, min: 0.9, max: 1.1),
              ),
            ),
          ),
        ),

        SizedBox(width: Responsive.scale(context, 6, min: 0.9, max: 1.1)),

        SizedBox(
          width: Responsive.scale(context, 35, min: 0.9, max: 1.1),
          child: Text(
            tempMax,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.scale(context, 14, min: 0.9, max: 1.1),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Weather Icon
  // ============================================================

  ({IconData icon, Color color}) _getWeatherIcon(String condition) {
    final cond = condition.trim().toLowerCase();

    if (cond.contains('thunderstorm') || cond.contains('storm')) {
      return (icon: Icons.storm, color: Colors.amberAccent);
    }

    if (cond.contains('hail')) {
      return (icon: Icons.hail, color: Colors.lightBlueAccent);
    }

    if (cond.contains('rain') ||
        cond.contains('shower') ||
        cond.contains('drizzle')) {
      return (icon: Icons.water_drop, color: Colors.lightBlueAccent);
    }

    if (cond.contains('snow') || cond.contains('sleet')) {
      return (icon: Icons.ac_unit, color: Colors.white);
    }

    if (cond.contains('wind') || cond.contains('breeze')) {
      return (icon: Icons.air, color: Colors.white60);
    }

    if (cond.contains('cloud') || cond.contains('overcast')) {
      return (icon: Icons.cloud, color: Colors.white70);
    }

    if (cond.contains('sun') || cond.contains('clear')) {
      return (icon: Icons.wb_sunny, color: Colors.amber);
    }

    if (cond.contains('mist') ||
        cond.contains('fog') ||
        cond.contains('haze')) {
      return (icon: Icons.foggy, color: Colors.white54);
    }

    return (icon: Icons.cloud_queue, color: Colors.white70);
  }
}
