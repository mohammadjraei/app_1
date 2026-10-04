import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AppGlassContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const AppGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 30.0,
  });

  @override
  State<AppGlassContainer> createState() => _AppGlassContainerState();
}

class _AppGlassContainerState extends State<AppGlassContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  ui.FragmentProgram? _fragmentProgram;

  @override
  void initState() {
    super.initState();

    // ===============================================================
    // Animation Controller
    // ===============================================================
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ===============================================================
    // Load Shader
    // ===============================================================
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _fragmentProgram = program;
      });
    } catch (e) {
      debugPrint('Liquid Glass Shader Error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ===============================================================
  // Build Shader
  // ===============================================================
  ui.FragmentShader? _buildShader() {
    final program = _fragmentProgram;

    if (program == null) {
      return null;
    }

    final shader = program.fragmentShader();

    // Animation time
    shader.setFloat(0, _animationController.value * 6.28318530718);

    // Wave intensity
    shader.setFloat(1, 0.012);

    // Wave frequency
    shader.setFloat(2, 7.0);

    // Reflection intensity
    shader.setFloat(3, 0.018);

    return shader;
  }

  @override
  Widget build(BuildContext context) {
    final customBorderRadius = BorderRadius.circular(widget.borderRadius);

    return Container(
      margin: widget.margin,

      // =============================================================
      // Shadow
      // =============================================================
      decoration: BoxDecoration(
        borderRadius: customBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: -2,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: -4,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: customBorderRadius,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // =========================================================
            // Blur
            // =========================================================
            ui.ImageFilter filter = ui.ImageFilter.blur(
              sigmaX: 7.0,
              sigmaY: 7.0,
            );

            // =========================================================
            // Shader
            // =========================================================
            if (_fragmentProgram != null) {
              final shader = _buildShader();

              if (shader != null) {
                filter = ui.ImageFilter.shader(shader);
              }
            }

            return BackdropFilter(
              filter: filter,

              child: Container(
                width: widget.width ?? double.infinity,
                height: widget.height,
                padding: widget.padding ?? const EdgeInsets.all(16.0),

                decoration: BoxDecoration(
                  borderRadius: customBorderRadius,

                  // ===================================================
                  // Glass Gradient
                  // ===================================================
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.4, 0.7, 1.0],
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.03),
                      Colors.white.withValues(alpha: 0.10),
                    ],
                  ),

                  // ===================================================
                  // Gradient Border
                  // ===================================================
                  border: GradientBorder.uniform(
                    width: 1.2,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.60),
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),

                // =====================================================
                // Main Layout
                // =====================================================
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===========================================================================
// Gradient Border
// ===========================================================================

class GradientBorder extends BoxBorder {
  final Gradient gradient;
  final double width;

  const GradientBorder._(this.gradient, this.width);

  factory GradientBorder.uniform({
    required Gradient gradient,
    double width = 1.0,
  }) {
    return GradientBorder._(gradient, width);
  }

  @override
  BorderSide get top => BorderSide(width: width);

  @override
  BorderSide get bottom => BorderSide(width: width);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    if (borderRadius != null) {
      final RRect rrect = borderRadius.toRRect(rect).deflate(width / 2);

      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawRect(rect.deflate(width / 2), paint);
    }
  }

  @override
  ShapeBorder scale(double t) {
    return GradientBorder._(gradient, width * t);
  }
}
