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
    final effectiveWidth = width ?? (iconSize != null ? iconSize! * 2.3 : 230.0);

    // In the 1024x314 logo asset:
    // - Document icon span: X = 17 to 287 (gap 287 to 325)
    // - "BillBooks" text span: X = 325 to 1006
    // The fraction from the left edge of the image to the start of "BillBooks" is 325 / 1024 = 31.74%.
    // The width of "BillBooks" text is (1006 - 325) / 1024 = 66.5% of effectiveWidth.
    final textLeftOffset = effectiveWidth * (325.0 / 1024.0);
    final textWidth = effectiveWidth * (681.0 / 1024.0);

    return SizedBox(
      width: effectiveWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BillBooks horizontal logo banner (document icon + BillBooks)
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
            const SizedBox(height: 4),

            // 2. Subtitle / Tagline: "PURCHASE VOUCHER AUTOMATION"
            // Positioned exactly under "BillBooks" (indented by document icon width)
            Padding(
              padding: EdgeInsets.only(left: textLeftOffset),
              child: SizedBox(
                width: textWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    'PURCHASE VOUCHER AUTOMATION',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C2946),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
