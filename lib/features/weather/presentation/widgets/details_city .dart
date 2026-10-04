import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive.dart';
import '../../controllers/weather_provider.dart';

class WeatherDetailsGrid extends StatefulWidget {
  const WeatherDetailsGrid({super.key});

  @override
  State<WeatherDetailsGrid> createState() => _WeatherDetailsGridState();
}

class _WeatherDetailsGridState extends State<WeatherDetailsGrid> {
  Timer? _sunTimer;

  @override
  void initState() {
    super.initState();

    // To update the sun position over time without making another API request.
    _sunTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sunTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>().weatherData;

    if (weather == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isAfterSunset = _isAfterSunset(weather.sunset);

    final String sunCardTitle = isAfterSunset ? 'Sunrise' : 'Sunset';

    final int sunCardTimestamp = isAfterSunset
        ? weather.nextSunrise
        : weather.sunset;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ====================================================
          // Background Glow
          // ====================================================

          Positioned(
            top: Responsive.scale(context, 80, min: 0.85, max: 1.1),
            left: -Responsive.scale(context, 50, min: 0.85, max: 1.1),
            child: Container(
              width: Responsive.scale(context, 260, min: 0.85, max: 1.1),
              height: Responsive.scale(context, 260, min: 0.85, max: 1.1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A2FF).withValues(alpha: 0.22),
              ),
            ),
          ),

          Positioned(
            bottom: Responsive.scale(context, 80, min: 0.85, max: 1.1),
            right: -Responsive.scale(context, 40, min: 0.85, max: 1.1),
            child: Container(
              width: Responsive.scale(context, 280, min: 0.85, max: 1.1),
              height: Responsive.scale(context, 280, min: 0.85, max: 1.1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8A2387).withValues(alpha: 0.28),
              ),
            ),
          ),

          Positioned(
            top: Responsive.heightPercent(context, 0.45),
            right: Responsive.widthPercent(context, 0.15),
            child: Container(
              width: Responsive.scale(context, 180, min: 0.85, max: 1.1),
              height: Responsive.scale(context, 180, min: 0.85, max: 1.1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFBB040).withValues(alpha: 0.15),
              ),
            ),
          ),

          // ====================================================
          // Main Content
          // ====================================================
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // Back Button
                // ==================================================

                Padding(
                  padding: EdgeInsets.only(
                    left: Responsive.scale(context, 16, min: 0.9, max: 1.1),
                    top: Responsive.scale(context, 12, min: 0.9, max: 1.1),
                    bottom: Responsive.scale(context, 4, min: 0.9, max: 1.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Responsive.scale(context, 18, min: 0.9, max: 1.1),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            Responsive.scale(context, 18, min: 0.9, max: 1.1),
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
                            width: Responsive.scale(
                              context,
                              1.2,
                              min: 0.9,
                              max: 1.1,
                            ),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: Responsive.scale(
                              context,
                              22,
                              min: 0.85,
                              max: 1.1,
                            ),
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

                // ==================================================
                // Grid
                // ==================================================
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.scale(
                        context,
                        16,
                        min: 0.9,
                        max: 1.1,
                      ),
                      vertical: Responsive.scale(
                        context,
                        8,
                        min: 0.9,
                        max: 1.1,
                      ),
                    ),
                    child: Center(
                      child: GridView(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: Responsive.scale(
                            context,
                            16,
                            min: 0.85,
                            max: 1.1,
                          ),
                          mainAxisSpacing: Responsive.scale(
                            context,
                            16,
                            min: 0.85,
                            max: 1.1,
                          ),
                          childAspectRatio: 0.82,
                        ),
                        children: [
                          // ==================================================
                          // 1. UV
                          // ==================================================

                          WeatherCard(
                            title: _getUvLabel(weather.uvIndex),
                            value: _formatUv(weather.uvIndex),
                            graphics: UvGaugeWidget(value: weather.uvIndex),
                          ),

                          // ==================================================
                          // 2. Humidity
                          // ==================================================
                          WeatherCard(
                            title: 'Humidity',
                            value: '${weather.humidity}%',
                            graphics: HumidityGaugeWidget(
                              percentage: (weather.humidity / 100)
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                            ),
                          ),

                          // ==================================================
                          // 3. Real Feel
                          // ==================================================
                          WeatherCard(
                            title: 'Real feel',
                            value: '${weather.feelsLike.round()}°',
                            graphics: RealFeelGaugeWidget(
                              temperature: weather.feelsLike,
                            ),
                          ),

                          // ==================================================
                          // 4. Wind
                          // ==================================================
                          WeatherCard(
                            title: _getWindDirection(weather.windDeg),
                            value: '${weather.windSpeed.toStringAsFixed(1)} ',
                            graphics: CompassWidget(
                              windDegree: weather.windDeg,
                            ),
                          ),

                          // ==================================================
                          // 5. Sunset / Sunrise
                          // ==================================================
                          WeatherCard(
                            title: sunCardTitle,
                            value: _formatUnixTime(
                              sunCardTimestamp,
                              weather.timezone,
                            ),
                            graphics: SunCurveWidget(
                              sunrise: weather.sunrise,
                              sunset: weather.sunset,
                              timezone: weather.timezone,
                            ),
                          ),

                          // ==================================================
                          // 6. Pressure
                          // ==================================================
                          WeatherCard(
                            title: 'Pressure',
                            value: '${weather.pressure}',
                            graphics: PressureGaugeWidget(
                              pressure: weather.pressure,
                            ),
                          ),
                        ],
                      ),
                    ),
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
  // Check whether today's sunset has already passed
  // ============================================================

  static bool _isAfterSunset(int sunset) {
    if (sunset <= 0) {
      return false;
    }

    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch / 1000;

    return nowSeconds >= sunset;
  }

  // ============================================================
  // UV Label
  // ============================================================

  static String _getUvLabel(double uv) {
    if (uv < 3) return 'UV Weak';
    if (uv < 6) return 'UV Moderate';
    if (uv < 8) return 'UV Strong';
    if (uv < 11) return 'UV Very High';

    return 'UV Extreme';
  }

  // ============================================================
  // UV Number
  // ============================================================

  static String _formatUv(double uv) {
    if (uv == 0) return '0';

    if (uv % 1 == 0) {
      return uv.toInt().toString();
    }

    return uv.toStringAsFixed(1);
  }

  // ============================================================
  // Wind Direction
  // ============================================================

  static String _getWindDirection(int degree) {
    const directions = [
      'North',
      'North-East',
      'East',
      'South-East',
      'South',
      'South-West',
      'West',
      'North-West',
    ];

    final normalized = ((degree % 360) + 360) % 360;

    final index = ((normalized + 22.5) / 45).floor() % 8;

    return directions[index];
  }

  // ============================================================
  // Unix → Local Time
  // ============================================================

  static String _formatUnixTime(int timestamp, int timezoneOffset) {
    if (timestamp <= 0) {
      return '--:--';
    }

    final utc = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );

    final local = utc.add(Duration(seconds: timezoneOffset));

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

// ============================================================
// Weather Card
// ============================================================

class WeatherCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget graphics;

  const WeatherCard({
    super.key,
    required this.title,
    required this.value,
    required this.graphics,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        Responsive.scale(context, 32, min: 0.9, max: 1.1),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              Responsive.scale(context, 32, min: 0.9, max: 1.1),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: Responsive.scale(context, 1.2, min: 0.9, max: 1.1),
            ),
          ),
          padding: EdgeInsets.all(
            Responsive.scale(context, 20, min: 0.85, max: 1.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: Responsive.scale(
                        context,
                        15,
                        min: 0.85,
                        max: 1.1,
                      ),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(
                    height: Responsive.scale(context, 6, min: 0.9, max: 1.1),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.scale(
                        context,
                        28,
                        min: 0.85,
                        max: 1.1,
                      ),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  height: Responsive.scale(context, 64, min: 0.85, max: 1.1),
                  width: Responsive.scale(context, 78, min: 0.85, max: 1.1),
                  child: graphics,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 1. UV Gauge
// ============================================================

class UvGaugeWidget extends StatelessWidget {
  final double value;

  const UvGaugeWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final gaugeSize = Responsive.scale(context, 60, min: 0.85, max: 1.1);

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(gaugeSize, gaugeSize),
          painter: UvArcPainter(value: value),
        ),
        Text(
          value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.scale(context, 18, min: 0.85, max: 1.1),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class UvArcPainter extends CustomPainter {
  final double value;

  UvArcPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width * 0.4;

    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    // ========================================================
    // UV Gradient
    // ========================================================

    final gradient = const SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        Colors.purple,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.red,
      ],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    // ========================================================
    // Background Arc
    // ========================================================

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.12);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // ========================================================
    // Active UV Arc
    // ========================================================

    final normalized = (value / 11).clamp(0.0, 1.0).toDouble();

    if (normalized > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * normalized,
        false,
        arcPaint,
      );
    }

    // ========================================================
    // Indicator
    // ========================================================

    final currentAngle = startAngle + (sweepAngle * normalized);

    final indicatorX = center.dx + radius * cos(currentAngle);

    final indicatorY = center.dy + radius * sin(currentAngle);

    final dotPaint = Paint()..color = Colors.green;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03;

    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      size.width * 0.08,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      size.width * 0.08,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant UvArcPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

// ============================================================
// 2. Humidity
// ============================================================

class HumidityGaugeWidget extends StatelessWidget {
  final double percentage;

  const HumidityGaugeWidget({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final gaugeSize = Responsive.scale(context, 60, min: 0.85, max: 1.1);

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(gaugeSize, gaugeSize),
          painter: HumidityArcPainter(percentage: percentage),
        ),
        Icon(
          Icons.water_drop_rounded,
          color: const Color(0xFF00A2FF),
          size: Responsive.scale(context, 22, min: 0.85, max: 1.1),
        ),
      ],
    );
  }
}

class HumidityArcPainter extends CustomPainter {
  final double percentage;

  HumidityArcPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    const startAngle = pi * 0.75;

    const sweepAngle = pi * 1.5;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1083
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.15);

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1083
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00A2FF);

    final normalized = percentage.clamp(0.0, 1.0).toDouble();

    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * normalized,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant HumidityArcPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

// ============================================================
// 3. Real Feel
// ============================================================

class RealFeelGaugeWidget extends StatelessWidget {
  final double temperature;

  const RealFeelGaugeWidget({super.key, required this.temperature});

  @override
  Widget build(BuildContext context) {
    final gaugeSize = Responsive.scale(context, 60, min: 0.85, max: 1.1);

    return CustomPaint(
      size: Size(gaugeSize, gaugeSize),
      painter: RealFeelPainter(temperature: temperature),
    );
  }
}

class RealFeelPainter extends CustomPainter {
  final double temperature;

  RealFeelPainter({required this.temperature});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    const startAngle = pi * 0.75;

    final bluePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1083
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF00A2FF);

    final greenPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1083
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2CE080);

    final orangePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1083
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF9F1C);

    canvas.drawArc(rect, startAngle, pi * 0.5, false, bluePaint);

    canvas.drawArc(rect, pi * 1.28, pi * 0.45, false, greenPaint);

    canvas.drawArc(rect, pi * 1.76, pi * 0.48, false, orangePaint);

    final center = Offset(size.width / 2, size.height / 2);

    const minTemperature = -10.0;
    const maxTemperature = 45.0;

    final normalized =
        ((temperature - minTemperature) / (maxTemperature - minTemperature))
            .clamp(0.0, 1.0)
            .toDouble();

    final angle = startAngle + pi * 1.5 * normalized;

    final needleLength = size.width * 0.2667;

    final needleEnd = Offset(
      center.dx + needleLength * cos(angle),
      center.dy + needleLength * sin(angle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    canvas.drawCircle(
      center,
      size.width * 0.075,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(center, size.width * 0.03, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant RealFeelPainter oldDelegate) {
    return oldDelegate.temperature != temperature;
  }
}

// ============================================================
// 4. Compass / Wind
// ============================================================

class CompassWidget extends StatelessWidget {
  final int windDegree;

  const CompassWidget({super.key, required this.windDegree});

  @override
  Widget build(BuildContext context) {
    final compassSize = Responsive.scale(context, 64, min: 0.85, max: 1.1);

    return CustomPaint(
      size: Size(compassSize, compassSize),
      painter: CompassPainter(windDegree: windDegree),
    );
  }
}

class CompassPainter extends CustomPainter {
  final int windDegree;

  CompassPainter({required this.windDegree});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2 - 2;

    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = size.width * 0.014;

    // ========================================================
    // Compass ticks
    // ========================================================

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180;

      final isMajor = i % 15 == 0;

      final tickLength = isMajor ? size.width * 0.086 : size.width * 0.055;

      final outer = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final inner = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );

      canvas.drawLine(inner, outer, tickPaint);
    }

    // ========================================================
    // Direction labels
    // ========================================================

    void drawDirectionText(String text, Offset position) {
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: size.width * 0.1406,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        ),
      );
    }

    final textRadius = radius - size.width * 0.1484;

    drawDirectionText('N', Offset(center.dx, center.dy - textRadius));

    drawDirectionText('S', Offset(center.dx, center.dy + textRadius));

    drawDirectionText('E', Offset(center.dx + textRadius, center.dy));

    drawDirectionText('W', Offset(center.dx - textRadius, center.dy));

    // ========================================================
    // Wind needle
    // ========================================================

    final normalizedDegree = ((windDegree % 360) + 360) % 360;

    final angle = normalizedDegree * pi / 180;

    final needleAngle = angle - pi / 2;

    final needleLength = size.width * 0.3125;

    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    final needleStart = Offset(
      center.dx - size.width * 0.125 * cos(needleAngle),
      center.dy - size.width * 0.125 * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = const Color(0xFF00A2FF)
      ..strokeWidth = size.width * 0.0547
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(needleStart, needleEnd, needlePaint);

    // ========================================================
    // Center
    // ========================================================

    canvas.drawCircle(
      center,
      size.width * 0.21875,
      Paint()..color = const Color(0xFF00A2FF),
    );

    // The previous m/s unit was intentionally removed.
    // Wind speed is displayed in km/h in the WeatherCard.
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.windDegree != windDegree;
  }
}

// ============================================================
// 5. Sunset - REAL TIME
// ============================================================

class SunCurveWidget extends StatelessWidget {
  final int sunrise;
  final int sunset;
  final int timezone;

  const SunCurveWidget({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.timezone,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _calculateSunProgress();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: Responsive.scale(context, 78, min: 0.85, max: 1.1),
          height: Responsive.scale(context, 36, min: 0.85, max: 1.1),
          child: CustomPaint(
            painter: SunCurvePainter(
              progress: progress,
              isDay: progress >= 0.0 && progress <= 1.0,
            ),
          ),
        ),
        SizedBox(height: Responsive.scale(context, 2, min: 0.9, max: 1.1)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTime(sunrise, timezone),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: Responsive.scale(context, 10, min: 0.85, max: 1.1),
              ),
            ),
            Text(
              _formatTime(sunset, timezone),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: Responsive.scale(context, 10, min: 0.85, max: 1.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateSunProgress() {
    if (sunrise <= 0 || sunset <= 0) {
      return -1.0;
    }

    final nowUtc = DateTime.now().toUtc();

    final nowSeconds = nowUtc.millisecondsSinceEpoch / 1000.0;

    final totalSeconds = (sunset - sunrise).toDouble();

    if (totalSeconds <= 0) {
      return -1.0;
    }

    return ((nowSeconds - sunrise) / totalSeconds)
        .clamp(-0.20, 1.20)
        .toDouble();
  }

  static String _formatTime(int timestamp, int timezone) {
    if (timestamp <= 0) {
      return '--:--';
    }

    final utc = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );

    final local = utc.add(Duration(seconds: timezone));

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class SunCurvePainter extends CustomPainter {
  final double progress;
  final bool isDay;

  SunCurvePainter({required this.progress, required this.isDay});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final horizonY = height * 0.72;

    // ========================================================
    // Horizon
    // ========================================================

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = size.width * 0.0128;

    double startX = 0;

    final dashLength = size.width * 0.0256;
    final dashSpacing = size.width * 0.0513;

    while (startX < width) {
      canvas.drawLine(
        Offset(startX, horizonY),
        Offset(startX + dashLength, horizonY),
        dashPaint,
      );

      startX += dashSpacing;
    }

    // ========================================================
    // Sun curve
    // ========================================================

    final path = Path();

    path.moveTo(width * 0.0513, height - 2);

    path.cubicTo(width * 0.25, height - 2, width * 0.25, 2, width * 0.5, 2);

    path.cubicTo(
      width * 0.75,
      2,
      width * 0.75,
      height - 2,
      width * 0.9487,
      height - 2,
    );

    final curveGradient = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFF6C63FF), Color(0xFF6C63FF), Color(0xFFFBB040)],
      stops: [0.0, 0.3, 0.65],
    );

    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.0513
      ..strokeCap = StrokeCap.round
      ..shader = curveGradient.createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(path, curvePaint);

    // ========================================================
    // Current Sun Position
    // ========================================================

    if (!isDay) {
      return;
    }

    final p = progress.clamp(0.0, 1.0).toDouble();

    final sunX = width * 0.0513 + (width * 0.8974) * p;

    final normalizedX = ((sunX - width * 0.0513) / (width * 0.8974))
        .clamp(0.0, 1.0)
        .toDouble();

    final sunY = (height - 2) - sin(normalizedX * pi) * (height - 7);

    final sunCenter = Offset(sunX, sunY);

    // Glow
    canvas.drawCircle(
      sunCenter,
      size.width * 0.1026,
      Paint()..color = const Color(0xFFFBB040).withValues(alpha: 0.16),
    );

    // Sun
    canvas.drawCircle(
      sunCenter,
      size.width * 0.0513,
      Paint()..color = const Color(0xFFFBB040),
    );

    canvas.drawCircle(
      sunCenter,
      size.width * 0.0513,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.0128,
    );
  }

  @override
  bool shouldRepaint(covariant SunCurvePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDay != isDay;
  }
}

// ============================================================
// 6. Pressure
// ============================================================

class PressureGaugeWidget extends StatelessWidget {
  final int pressure;

  const PressureGaugeWidget({super.key, required this.pressure});

  @override
  Widget build(BuildContext context) {
    final gaugeSize = Responsive.scale(context, 60, min: 0.85, max: 1.1);

    return CustomPaint(
      size: Size(gaugeSize, gaugeSize),
      painter: PressureArcPainter(pressure: pressure),
    );
  }
}

class PressureArcPainter extends CustomPainter {
  final int pressure;

  PressureArcPainter({required this.pressure});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width * 0.4;

    // ========================================================
    // Angles
    // ========================================================

    const startAngle = pi * 0.75;

    const sweepAngle = pi * 1.5;

    // ========================================================
    // Background Arc
    // ========================================================

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.12);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // ========================================================
    // Pressure Normalization
    // ========================================================

    const minPressure = 980.0;
    const maxPressure = 1040.0;

    final normalized = ((pressure - minPressure) / (maxPressure - minPressure))
        .clamp(0.0, 1.0)
        .toDouble();

    // ========================================================
    // Pressure Gradient
    // ========================================================

    final gradient = const SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [Colors.blue, Colors.lightBlue, Colors.purple],
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    // ========================================================
    // Active Pressure Arc
    // ========================================================

    if (normalized > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * normalized,
        false,
        activePaint,
      );
    }

    // ========================================================
    // Current Pressure Marker
    // ========================================================

    final currentAngle = startAngle + sweepAngle * normalized;

    final indicatorX = center.dx + radius * cos(currentAngle);

    final indicatorY = center.dy + radius * sin(currentAngle);

    // Indicator
    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      size.width * 0.08,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      size.width * 0.08,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.03,
    );
  }

  @override
  bool shouldRepaint(covariant PressureArcPainter oldDelegate) {
    return oldDelegate.pressure != pressure;
  }
}
