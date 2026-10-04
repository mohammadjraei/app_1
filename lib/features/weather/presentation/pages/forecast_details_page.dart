import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive.dart';
import '../../../weather/controllers/weather_provider.dart';

class ForecastDetailsPage extends StatelessWidget {
  const ForecastDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    final forecast = weatherProvider.weatherData?.forecast ?? [];

    // ============================================================
    // Display 7 days
    // ============================================================

    final days = forecast.take(7).toList();

    if (days.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0D14),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Forecast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: Padding(
            padding: EdgeInsets.only(
              left: Responsive.scale(context, 16),
              top: Responsive.scale(context, 12),
              bottom: Responsive.scale(context, 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Responsive.scale(context, 18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      Responsive.scale(context, 18),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: Responsive.scale(context, 1.2),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: Responsive.scale(context, 22),
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Center(
          child: Text(
            'No forecast data',
            style: TextStyle(
              color: Colors.white54,
              fontSize: Responsive.scale(context, 15),
            ),
          ),
        ),
      );
    }

    final allTemperatures = <double>[
      for (final day in days) ...[day.minTemp, day.maxTemp],
    ];

    final lowestTemperature = allTemperatures.reduce((a, b) => a < b ? a : b);

    final highestTemperature = allTemperatures.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Forecast',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.only(
            left: Responsive.scale(context, 16),
            top: Responsive.scale(context, 12),
            bottom: Responsive.scale(context, 4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Responsive.scale(context, 18)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.scale(context, 18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: Responsive.scale(context, 1.2),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: Responsive.scale(context, 22),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: Responsive.scale(context, 70),
            left: Responsive.scale(context, -100),
            child: _BackgroundGlow(
              size: Responsive.scale(context, 280),
              color: const Color(0xFF6C63FF),
            ),
          ),
          Positioned(
            top: Responsive.scale(context, 360),
            right: Responsive.scale(context, -120),
            child: _BackgroundGlow(
              size: Responsive.scale(context, 300),
              color: const Color(0xFF38BDF8),
            ),
          ),
          Positioned(
            bottom: 0,
            left: Responsive.scale(context, 80),
            child: _BackgroundGlow(
              size: Responsive.scale(context, 320),
              color: const Color(0xFF8B5CF6),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Responsive.scale(context, 12),
                Responsive.scale(context, 18),
                Responsive.scale(context, 12),
                Responsive.scale(context, 30),
              ),
              child: WeatherTemperatureGlassCard(
                days: days,
                lowestTemperature: lowestTemperature,
                highestTemperature: highestTemperature,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.13),
          ),
        ),
      ),
    );
  }
}

class WeatherTemperatureGlassCard extends StatelessWidget {
  final List<dynamic> days;
  final double lowestTemperature;
  final double highestTemperature;

  const WeatherTemperatureGlassCard({
    super.key,
    required this.days,
    required this.lowestTemperature,
    required this.highestTemperature,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final dayWidth = Responsive.scale(context, 110);

        final contentWidth = (dayWidth * days.length).ceilToDouble();

        return ClipRRect(
          borderRadius: BorderRadius.circular(Responsive.scale(context, 32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  Responsive.scale(context, 32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.055),
                    Colors.white.withValues(alpha: 0.075),
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.17),
                  width: Responsive.scale(context, 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: Responsive.scale(context, 40),
                    spreadRadius: Responsive.scale(context, -5),
                    offset: Offset(0, Responsive.scale(context, 20)),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.025),
                    blurRadius: Responsive.scale(context, 1),
                    spreadRadius: Responsive.scale(context, 1),
                    offset: Offset(0, Responsive.scale(context, -1)),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.scale(context, 16),
                  Responsive.scale(context, 20),
                  Responsive.scale(context, 16),
                  Responsive.scale(context, 18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context),

                    SizedBox(height: Responsive.scale(context, 22)),

                    ClipRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: contentWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDayLabels(context, dayWidth),

                              SizedBox(height: Responsive.scale(context, 14)),

                              _buildWeatherIcons(context, dayWidth),

                              SizedBox(height: Responsive.scale(context, 10)),

                              _buildMaxTemperatures(context, dayWidth),

                              SizedBox(height: Responsive.scale(context, 4)),

                              SizedBox(
                                width: contentWidth,
                                height: Responsive.scale(context, 270),
                                child: ClipRect(
                                  child: CustomPaint(
                                    painter: TemperatureChartPainter(
                                      days: days,
                                      lowestTemperature: lowestTemperature,
                                      highestTemperature: highestTemperature,
                                    ),
                                  ),
                                ),
                              ),

                              _buildMinTemperatures(context, dayWidth),

                              SizedBox(height: Responsive.scale(context, 16)),

                              _buildWindInformation(context, dayWidth),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Header
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: Responsive.scale(context, 48),
      child: Row(
        children: [
          Container(
            width: Responsive.scale(context, 42),
            height: Responsive.scale(context, 42),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.09),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: Responsive.scale(context, 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.04),
                  blurRadius: Responsive.scale(context, 8),
                  spreadRadius: Responsive.scale(context, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.thermostat_rounded,
              color: Colors.white,
              size: Responsive.scale(context, 23),
            ),
          ),
          SizedBox(width: Responsive.scale(context, 12)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperature',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.scale(context, 17),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Responsive.scale(context, 2)),
                Text(
                  '6-day forecast',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: Responsive.scale(context, 12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Day Labels
  // ============================================================

  Widget _buildDayLabels(BuildContext context, double dayWidth) {
    return SizedBox(
      width: dayWidth * days.length,
      height: Responsive.scale(context, 34),
      child: Row(
        children: List.generate(days.length, (index) {
          final day = days[index];

          final today = _isToday(day.dateTxt);

          return SizedBox(
            width: dayWidth,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.scale(context, 10),
                  vertical: Responsive.scale(context, 6),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.scale(context, 20),
                  ),
                  color: today
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
                  border: today
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: Responsive.scale(context, 1),
                        )
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatDayLabel(day.dateTxt),
                    style: TextStyle(
                      color: today ? Colors.white : Colors.white54,
                      fontSize: Responsive.scale(context, 12),
                      fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // Weather Icons
  // ============================================================

  Widget _buildWeatherIcons(BuildContext context, double dayWidth) {
    return SizedBox(
      width: dayWidth * days.length,
      height: Responsive.scale(context, 60),
      child: Row(
        children: List.generate(days.length, (index) {
          final day = days[index];

          final weather = _getWeatherIcon(day.condition);

          return SizedBox(
            width: dayWidth,
            child: Center(
              child: Container(
                width: Responsive.scale(context, 54),
                height: Responsive.scale(context, 54),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.055),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.075),
                    width: Responsive.scale(context, 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: weather.color.withValues(alpha: 0.09),
                      blurRadius: Responsive.scale(context, 14),
                      spreadRadius: Responsive.scale(context, 1),
                    ),
                  ],
                ),
                child: Icon(
                  weather.icon,
                  color: weather.color,
                  size: Responsive.scale(context, 34),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // Max Temperature
  // ============================================================

  Widget _buildMaxTemperatures(BuildContext context, double dayWidth) {
    return SizedBox(
      width: dayWidth * days.length,
      height: Responsive.scale(context, 38),
      child: Row(
        children: List.generate(days.length, (index) {
          final day = days[index];

          return SizedBox(
            width: dayWidth,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${day.maxTemp.round()}°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.scale(context, 19),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // Min Temperature
  // ============================================================

  Widget _buildMinTemperatures(BuildContext context, double dayWidth) {
    return SizedBox(
      width: dayWidth * days.length,
      height: Responsive.scale(context, 34),
      child: Row(
        children: List.generate(days.length, (index) {
          final day = days[index];

          return SizedBox(
            width: dayWidth,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${day.minTemp.round()}°',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: Responsive.scale(context, 15),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // Wind Information
  // ============================================================

  Widget _buildWindInformation(BuildContext context, double dayWidth) {
    final totalWidth = dayWidth * days.length;

    return SizedBox(
      width: totalWidth,
      height: Responsive.scale(context, 66),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Responsive.scale(context, 22)),
          color: Colors.white.withValues(alpha: 0.045),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
            width: Responsive.scale(context, 1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Responsive.scale(context, 21)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(days.length, (index) {
              final day = days[index];

              // ==================================================
              // Important:
              //
              // day.windSpeed comes from Open-Meteo in km/h.
              //
              // Therefore, we no longer multiply by 3.6.
              //
              // Example:
              //
              // API = 25.9
              // Display = 25.9 km/h
              // ==================================================

              final double windKmh = day.windSpeed;

              final itemWidth = days.isNotEmpty
                  ? (totalWidth - Responsive.scale(context, 2)) / days.length
                  : dayWidth;

              return SizedBox(
                width: itemWidth,
                height: Responsive.scale(context, 66),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.scale(context, 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.air_rounded,
                        color: Colors.white38,
                        size: Responsive.scale(context, 19),
                      ),
                      SizedBox(height: Responsive.scale(context, 5)),
                      SizedBox(
                        height: Responsive.scale(context, 14),
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${windKmh.toStringAsFixed(1)} km/h',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: Responsive.scale(context, 10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Format Day
  // ============================================================

  String _formatDayLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);

      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final target = DateTime(date.year, date.month, date.day);

      final difference = target.difference(today).inDays;

      if (difference == 0) {
        return 'Today';
      }

      if (difference == 1) {
        return 'Tomorrow';
      }

      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return names[date.weekday - 1];
    } catch (_) {
      return 'Day';
    }
  }

  // ============================================================
  // Is Today
  // ============================================================

  bool _isToday(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);

      final now = DateTime.now();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // Weather Icon
  // ============================================================

  ({IconData icon, Color color}) _getWeatherIcon(String condition) {
    final value = condition.trim().toLowerCase();

    if (value.contains('thunderstorm') || value.contains('storm')) {
      return (icon: Icons.thunderstorm_rounded, color: const Color(0xFFFFD54F));
    }

    if (value.contains('rain') ||
        value.contains('drizzle') ||
        value.contains('shower')) {
      return (icon: Icons.water_drop_rounded, color: const Color(0xFF69C8FF));
    }

    if (value.contains('snow') || value.contains('sleet')) {
      return (icon: Icons.ac_unit_rounded, color: const Color(0xFF9DDCFF));
    }

    if (value.contains('cloud')) {
      return (icon: Icons.cloud_rounded, color: Colors.white70);
    }

    if (value.contains('mist') ||
        value.contains('fog') ||
        value.contains('haze')) {
      return (icon: Icons.blur_on_rounded, color: Colors.white54);
    }

    return (icon: Icons.wb_sunny_rounded, color: const Color(0xFFFFE066));
  }
}

// ============================================================
// Temperature Chart Painter
// ============================================================

class TemperatureChartPainter extends CustomPainter {
  final List<dynamic> days;
  final double lowestTemperature;
  final double highestTemperature;

  TemperatureChartPainter({
    required this.days,
    required this.lowestTemperature,
    required this.highestTemperature,
  });

  // ============================================================
  // Max Temperature Gradient
  // ============================================================

  List<Color> _getMaxTemperatureGradients(double temp) {
    if (temp >= 35) {
      return const [Color(0xFFFF1744), Color(0xFFD50000), Color(0xFF900C3F)];
    } else if (temp >= 28) {
      return const [Color(0xFFFF5252), Color(0xFFFF1744), Color(0xFFE60000)];
    } else if (temp >= 20) {
      return const [Color(0xFFFF9800), Color(0xFFFF6D00), Color(0xFFE65100)];
    } else {
      return const [Color(0xFFFFD9A6), Color(0xFFFFB86B), Color(0xFFFF8F3D)];
    }
  }

  // ============================================================
  // Min Temperature Gradient
  // ============================================================

  List<Color> _getMinTemperatureGradients(double temp) {
    if (temp >= 20) {
      return const [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)];
    } else if (temp >= 10) {
      return const [Color(0xFFB7E7FF), Color(0xFF74C9FF), Color(0xFF38A8FF)];
    } else if (temp >= 0) {
      return const [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1D4ED8)];
    } else {
      return const [Color(0xFFA78BFA), Color(0xFF6366F1), Color(0xFF3730A3)];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    canvas.save();

    canvas.clipRect(Offset.zero & size);

    final range = (highestTemperature - lowestTemperature).abs();

    final safeRange = range < 1 ? 1.0 : range;

    // Responsive proportions based on the actual chart size.
    final topPadding = size.height * 0.1185;
    final bottomPadding = size.height * 0.1185;

    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartHeight <= 0) {
      canvas.restore();
      return;
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = size.width * 0.0015;

    for (int i = 0; i < 5; i++) {
      final y = topPadding + (chartHeight / 4) * i;

      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
        size,
      );
    }

    final columnWidth = size.width / days.length;

    final maxPoints = <Offset>[];
    final minPoints = <Offset>[];

    for (int index = 0; index < days.length; index++) {
      final day = days[index];

      final x = (index * columnWidth) + (columnWidth / 2);

      final maxY = _temperatureToY(
        day.maxTemp,
        topPadding,
        chartHeight,
        safeRange,
      );

      final minY = _temperatureToY(
        day.minTemp,
        topPadding,
        chartHeight,
        safeRange,
      );

      maxPoints.add(Offset(x, maxY));
      minPoints.add(Offset(x, minY));
    }

    final maxColors = _getMaxTemperatureGradients(highestTemperature);

    final minColors = _getMinTemperatureGradients(lowestTemperature);

    if (maxPoints.length >= 2) {
      final areaPath = Path();

      areaPath.moveTo(maxPoints.first.dx, maxPoints.first.dy);

      for (int i = 0; i < maxPoints.length - 1; i++) {
        _addSmoothCurve(areaPath, maxPoints[i], maxPoints[i + 1]);
      }

      for (int i = minPoints.length - 1; i > 0; i--) {
        _addSmoothCurve(areaPath, minPoints[i], minPoints[i - 1]);
      }

      areaPath.lineTo(minPoints.first.dx, minPoints.first.dy);

      areaPath.close();

      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            maxColors[1].withValues(alpha: 0.18),
            minColors[1].withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));

      canvas.drawPath(areaPath, areaPaint);
    }

    _drawSmoothLine(
      canvas,
      maxPoints,
      Paint()
        ..color = maxColors[1].withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.0145
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    _drawSmoothLine(
      canvas,
      minPoints,
      Paint()
        ..color = minColors[1].withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.0145
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final maxGradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: maxColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.00365
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawSmoothLine(canvas, maxPoints, maxGradientPaint);

    final minGradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: minColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.00365
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawSmoothLine(canvas, minPoints, minGradientPaint);

    for (int i = 0; i < maxPoints.length; i++) {
      _drawTemperaturePoint(canvas, maxPoints[i], maxColors[1], size);

      _drawTemperaturePoint(canvas, minPoints[i], minColors[1], size);
    }

    canvas.restore();
  }

  void _drawSmoothLine(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);

      return;
    }

    final path = Path();

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      _addSmoothCurve(path, points[i], points[i + 1]);
    }

    canvas.drawPath(path, paint);
  }

  void _addSmoothCurve(Path path, Offset first, Offset second) {
    final distance = (second.dx - first.dx) * 0.42;

    path.cubicTo(
      first.dx + distance,
      first.dy,
      second.dx - distance,
      second.dy,
      second.dx,
      second.dy,
    );
  }

  void _drawTemperaturePoint(
    Canvas canvas,
    Offset point,
    Color color,
    Size size,
  ) {
    final glowRadius = size.width * 0.0082;

    final outerRadius = size.width * 0.00545;

    final innerRadius = size.width * 0.00273;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

    canvas.drawCircle(point, glowRadius, glowPaint);

    final outerPaint = Paint()..color = color;

    canvas.drawCircle(point, outerRadius, outerPaint);

    final innerPaint = Paint()..color = const Color(0xFF11131B);

    canvas.drawCircle(point, innerRadius, innerPaint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    Size size,
  ) {
    final dashWidth = size.width * 0.00455;

    final dashSpace = size.width * 0.00636;

    double currentX = start.dx;

    while (currentX < end.dx) {
      final endX = (currentX + dashWidth).clamp(start.dx, end.dx);

      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(endX, start.dy),
        paint,
      );

      currentX += dashWidth + dashSpace;
    }
  }

  double _temperatureToY(
    double temperature,
    double topPadding,
    double chartHeight,
    double range,
  ) {
    final normalized = (temperature - lowestTemperature) / range;

    return topPadding + chartHeight - (normalized * chartHeight);
  }

  @override
  bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) {
    return oldDelegate.days != days ||
        oldDelegate.lowestTemperature != lowestTemperature ||
        oldDelegate.highestTemperature != highestTemperature;
  }
}
