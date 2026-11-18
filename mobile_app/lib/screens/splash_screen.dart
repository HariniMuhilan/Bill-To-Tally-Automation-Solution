import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

/// Fast, GPU-composited launch intro (~900ms) with BillBooks logo Hero handoff.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _logoVisible = false;
  bool _taglineVisible = false;
  Timer? _taglineTimer;
  Timer? _doneTimer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete();
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _logoVisible = true);
    });

    _taglineTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _taglineVisible = true);
    });

    _doneTimer = Timer(const Duration(milliseconds: 950), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _taglineTimer?.cancel();
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LiquidBackgroundPainter(),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    child: AnimatedOpacity(
                      opacity: _logoVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      child: AnimatedScale(
                        scale: _logoVisible ? 1.0 : 0.88,
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        child: Hero(
                          tag: 'billbooks_brand_logo',
                          child: Image.asset(
                            'assets/images/billbooks_header_logo.png',
                            width: 240,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/billbooks_logo.png',
                              width: 240,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: _taglineVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'PURCHASE VOUCHER AUTOMATION',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
