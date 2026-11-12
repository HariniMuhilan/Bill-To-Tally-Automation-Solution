import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Background Painter rendering the warm liquid background gradient,
/// radial glow overlays (top-left pink, bottom-right warm orange),
/// and exact 3D wavy liquid glass ribbons matching the reference design.
class LiquidBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base linear gradient: 170deg from #fbd9c9 -> #fde6d6 -> #fcd9b8 -> #fbc590
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-0.3, -1.0),
        end: Alignment(0.3, 1.0),
        colors: [
          AppColors.bg1,
          AppColors.bg2,
          AppColors.bg3,
          AppColors.bg4,
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // 2. Soft light-pink glow at the top-left
    final pinkGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.9, -0.9),
        radius: 0.9,
        colors: [
          AppColors.radialPink.withValues(alpha: 0.85),
          AppColors.radialPink.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), pinkGlow);

    // 3. Warm orange radial glow at the bottom-right
    final orangeGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.9, 0.9),
        radius: 1.1,
        colors: [
          AppColors.radialOrange.withValues(alpha: 0.65),
          AppColors.radialOrange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), orangeGlow);

    // 4. Exact 3D Wavy Liquid Glass Ribbons (Luminous soft under-glow + sharp crest highlight)
    // Wave 1: Upper header wave
    _drawLiquidWave(
      canvas,
      start: Offset(0, size.height * 0.08),
      cp1: Offset(size.width * 0.40, size.height * 0.12),
      cp2: Offset(size.width * 0.75, size.height * 0.05),
      end: Offset(size.width, size.height * 0.09),
      strokeWidth: 1.5,
      glowWidth: 20.0,
      glowOpacity: 0.32,
      crestOpacity: 0.80,
    );

    // Wave 2: Upper-middle sweeping wave
    _drawLiquidWave(
      canvas,
      start: Offset(0, size.height * 0.28),
      cp1: Offset(size.width * 0.35, size.height * 0.33),
      cp2: Offset(size.width * 0.70, size.height * 0.24),
      end: Offset(size.width, size.height * 0.27),
      strokeWidth: 1.3,
      glowWidth: 18.0,
      glowOpacity: 0.22,
      crestOpacity: 0.65,
    );

    // Wave 3: Middle wave behind receipt empty state
    _drawLiquidWave(
      canvas,
      start: Offset(0, size.height * 0.50),
      cp1: Offset(size.width * 0.30, size.height * 0.55),
      cp2: Offset(size.width * 0.65, size.height * 0.46),
      end: Offset(size.width, size.height * 0.52),
      strokeWidth: 1.4,
      glowWidth: 22.0,
      glowOpacity: 0.28,
      crestOpacity: 0.85,
    );

    // Wave 4: Expressive lower sweeping S-curve
    _drawLiquidWave(
      canvas,
      start: Offset(0, size.height * 0.72),
      cp1: Offset(size.width * 0.40, size.height * 0.66),
      cp2: Offset(size.width * 0.65, size.height * 0.82),
      end: Offset(size.width, size.height * 0.75),
      strokeWidth: 1.6,
      glowWidth: 26.0,
      glowOpacity: 0.35,
      crestOpacity: 0.90,
    );

    // Wave 5: Bottom accent wave around floating nav
    _drawLiquidWave(
      canvas,
      start: Offset(0, size.height * 0.91),
      cp1: Offset(size.width * 0.30, size.height * 0.87),
      cp2: Offset(size.width * 0.70, size.height * 0.96),
      end: Offset(size.width, size.height * 0.90),
      strokeWidth: 1.5,
      glowWidth: 24.0,
      glowOpacity: 0.25,
      crestOpacity: 0.75,
    );
  }

  void _drawLiquidWave(
    Canvas canvas, {
    required Offset start,
    required Offset cp1,
    required Offset cp2,
    required Offset end,
    required double strokeWidth,
    required double glowWidth,
    required double glowOpacity,
    required double crestOpacity,
  }) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    // 1. Soft 3D translucent liquid under-ribbon glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: glowOpacity),
          Colors.white.withValues(alpha: glowOpacity * 0.7),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.30, 0.70, 1.0],
      ).createShader(Rect.fromPoints(start, end));
    canvas.drawPath(path, glowPaint);

    // 2. Sharp crest highlight line
    final crestPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: crestOpacity * 0.7),
          Colors.white.withValues(alpha: crestOpacity),
          Colors.white.withValues(alpha: crestOpacity * 0.5),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.20, 0.50, 0.80, 1.0],
      ).createShader(Rect.fromPoints(start, end));

    canvas.drawPath(path, crestPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Reusable Liquid Glass Container implementing the exact specifications:
/// - Light Glass (with optional blur)
/// - Dark Maroon Glass (GPU-optimized)
/// - Orange Glossy Button
class LiquidGlass extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDarkMaroon;
  final bool isOrangeGloss;
  final bool useBlur;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 22.0,
    this.padding = EdgeInsets.zero,
    this.isDarkMaroon = false,
    this.isOrangeGloss = false,
    this.useBlur = false,
    this.onTap,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.isOrangeGloss) {
      // Orange glossy button: gradient #ff8a3d -> #f0580e, shadow 0 5px 12px rgba(240,88,14,.45)
      content = Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.orangeStart, AppColors.orangeEnd],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF0580E).withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Inner highlights
            Positioned(
              top: 1,
              left: 8,
              right: 8,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Center(child: widget.child),
          ],
        ),
      );
    } else if (widget.isDarkMaroon) {
      // Dark maroon glass: linear-gradient(165deg, #9c3d62, #7a2347 40%, #5e1233)
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: const LinearGradient(
              begin: Alignment(-0.8, -1.0),
              end: Alignment(0.8, 1.0),
              colors: [
                AppColors.maroonLight,
                AppColors.maroonMid,
                AppColors.maroonDark,
              ],
              stops: [0.0, 0.4, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFFFFBED7).withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A1634).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: widget.alignment ?? Alignment.center,
            children: [
              // Soft pink glossy highlight across the upper right
              Positioned(
                top: -20,
                right: -20,
                width: 140,
                height: 100,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          const Color(0xFFFFBED7).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Inner top highlight line
              Positioned(
                top: 1,
                left: 12,
                right: 12,
                height: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.65),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        ),
      );
    } else {
      // Light glass surface: high-performance frosted gradient + bright inner highlights
      final lightCard = Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: const Alignment(-0.8, -1.0),
            end: const Alignment(0.8, 1.0),
            colors: [
              Colors.white.withValues(alpha: 0.72),
              const Color(0xFFFFF0E6).withValues(alpha: 0.50),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC86E46).withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: widget.alignment ?? Alignment.center,
          children: [
            // Inner highlight line
            Positioned(
              top: 1,
              left: 10,
              right: 10,
              height: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      );

      if (widget.useBlur) {
        content = ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: lightCard,
          ),
        );
      } else {
        content = ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: lightCard,
        );
      }
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: content,
        ),
      );
    }

    return content;
  }
}
