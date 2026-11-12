import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

class UpgradeScreen extends StatelessWidget {
  final StorageService storage;

  const UpgradeScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge & Title
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.orangeStart, AppColors.orangeEnd],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'PRO UPGRADE',
                            style: AppTypography.fontS(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upgrade Your Business',
                      textAlign: TextAlign.center,
                      style: AppTypography.fontL(
                        color: AppColors.brandInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unlock unlimited bill scanning, cloud sync, and instant accounting exports.',
                      textAlign: TextAlign.center,
                      style: AppTypography.fontS(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Main Pricing Card
              LiquidGlass(
                borderRadius: 22,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Business Pro Plan',
                          style: AppTypography.fontM(
                            color: AppColors.brandInk,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.maroonDark.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'POPULAR',
                            style: AppTypography.fontS(
                              color: AppColors.maroonDark,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹499',
                          style: AppTypography.fontNumber(
                            color: AppColors.brandInk,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ month',
                          style: AppTypography.fontS(
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0x2285727A)),
                    const SizedBox(height: 16),

                    // Feature List
                    _buildFeatureItem(
                      icon: Icons.auto_awesome_rounded,
                      text: 'Unlimited AI Voucher & OCR Scans',
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.sync_rounded,
                      text: 'Direct 1-Click Tally & Zoho Books Sync',
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.table_chart_rounded,
                      text: 'Multi-Store Continuous Excel Accumulation',
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.cloud_done_rounded,
                      text: 'Cloud Backup & Multi-Device Access',
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.payment_rounded,
                      text: 'Secure Payment Gateway (UPI, Cards, Netbanking)',
                    ),

                    const SizedBox(height: 22),

                    // Upgrade / Payment Button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Payment Gateway integration will be connected here soon!',
                            ),
                            backgroundColor: AppColors.maroonDark,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.orangeStart, AppColors.orangeEnd],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Upgrade with Payment Gateway',
                                style: AppTypography.fontM(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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

              const SizedBox(height: 20),

              // Bottom Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.mutedText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Razorpay / Stripe payment gateway checkout will be connected directly to this button.',
                        style: AppTypography.fontS(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: AppColors.successGreen),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.fontS(
              color: AppColors.brandInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
