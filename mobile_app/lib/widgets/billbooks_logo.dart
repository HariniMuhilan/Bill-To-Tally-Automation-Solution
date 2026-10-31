import 'package:flutter/material.dart';

class BillbooksLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double? iconSize;
  final bool showWordmark;

  const BillbooksLogo({
    super.key,
    this.width,
    this.height,
    this.iconSize,
    this.showWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    // When iconSize is provided (e.g. 84), width scales proportionally to ~175
    final effectiveWidth = width ?? (iconSize != null ? iconSize! * 2.05 : 175.0);

    return Image.asset(
      'assets/images/billbooks_logo.png',
      width: effectiveWidth,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        // Fallback for web paths
        return Image.network(
          'assets/images/billbooks_logo.png',
          width: effectiveWidth,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      },
    );
  }
}
