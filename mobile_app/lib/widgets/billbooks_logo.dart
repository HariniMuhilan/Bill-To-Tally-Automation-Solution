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
    // When iconSize is provided (e.g. 110 or 84), width scales proportionally
    final effectiveWidth = width ?? (iconSize != null ? iconSize! * 1.85 : 180.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Original master logo: Thermal Printer Icon + exact original "Billbooks" graphic
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
          const SizedBox(height: 5),

          // 2. Extracted subtitle text (rendered as real selectable/scalable text)
          Text(
            'PURCHASE VOUCHER AUTOMATION',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 9.5,
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
