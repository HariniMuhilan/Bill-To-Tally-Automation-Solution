import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps the mobile app in an elegant smartphone frame when running on Desktop/Laptop screens.
/// On actual mobile handsets (Android/iOS), it renders directly full-screen without frames.
class LaptopMobileFrame extends StatelessWidget {
  final Widget child;

  const LaptopMobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // If running on a native phone (narrow screen), don't add frame
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 500) {
          return child;
        }

        // On Laptop/Desktop screen, render mobile chassis preview
        return Scaffold(
          backgroundColor: const Color(0xFF1E121E), // Deep purple desktop backdrop
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Device Label Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smartphone, color: AppColors.accentOrange, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Mobile Preview Mode (390 x 844 px)',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Smartphone Handset Chassis
                  Container(
                    width: 390,
                    height: 844,
                    decoration: BoxDecoration(
                      color: AppColors.blushIvory,
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(color: AppColors.forestCharcoal, width: 10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
