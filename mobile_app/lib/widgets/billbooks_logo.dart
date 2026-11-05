import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    // Proportional width for the horizontal logo banner
    final effectiveWidth = width ?? (iconSize != null ? iconSize! * 2.4 : 220.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. BillBooks horizontal logo banner (document icon with curved arrow + BillBooks text)
        Image.asset(
          'assets/images/billbooks_logo.png',
          width: effectiveWidth,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              'assets/images/billbooks_logo.png',
              width: effectiveWidth,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            );
          },
        ),

        if (showWordmark) ...[
          const SizedBox(height: 6),

          // 2. Subtitle / Tagline: "PURCHASE VOUCHER AUTOMATION" in DM Sans, color #7C2946
          Text(
            'PURCHASE VOUCHER AUTOMATION',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7C2946),
              letterSpacing: 2.2,
            ),
          ),
        ],
      ],
    );
  }
}
