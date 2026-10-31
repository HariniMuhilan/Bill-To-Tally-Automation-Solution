import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BillbooksLogo extends StatelessWidget {
  final double? iconSize;
  final bool showWordmark;

  const BillbooksLogo({
    super.key,
    this.iconSize,
    this.showWordmark = true,
    double? width,
    double? height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? 92.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Thermal printer logo icon (image only)
        Image.asset(
          'assets/images/billbooks_icon.png',
          width: effectiveIconSize,
          height: effectiveIconSize * 0.88,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              'assets/images/billbooks_icon.png',
              width: effectiveIconSize,
              height: effectiveIconSize * 0.88,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            );
          },
        ),

        if (showWordmark) ...[
          const SizedBox(height: 10),

          // 2. Primary Wordmark: "Bill" (Dark Forest/Teal) + "books" (Rich Plum)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Bill',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D2D2A),
                    letterSpacing: -0.8,
                  ),
                ),
                TextSpan(
                  text: 'books',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF70275B),
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 3),

          // 3. Subtitle / Tagline: "PURCHASE VOUCHER AUTOMATION"
          Text(
            'PURCHASE VOUCHER AUTOMATION',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF707175),
              letterSpacing: 2.2,
            ),
          ),
        ],
      ],
    );
  }
}
