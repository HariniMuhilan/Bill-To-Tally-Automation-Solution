import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

class UpgradePaywallDialog extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const UpgradePaywallDialog({
    super.key,
    this.onUpgrade,
  });

  static Future<bool?> show(BuildContext context, {VoidCallback? onUpgrade}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpgradePaywallDialog(
        onUpgrade: () {
          Navigator.of(ctx).pop(true);
          onUpgrade?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: LiquidGlass(
            borderRadius: 26,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.orangeStart, AppColors.orangeEnd],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  'Free Limit Reached (2/2)',
                  textAlign: TextAlign.center,
                  style: AppTypography.fontL(
                    color: AppColors.brandInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'You have used your 2 free bill uploads. Upgrade your account to continue uploading bills and unlock all accounting features.',
                  textAlign: TextAlign.center,
                  style: AppTypography.fontS(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // Feature List Container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Unlimited AI Voucher & OCR Scans',
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureRow(
                        icon: Icons.sync_rounded,
                        text: 'Direct 1-Click Tally & Zoho Sync',
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureRow(
                        icon: Icons.table_chart_rounded,
                        text: 'Multi-Store Continuous Excel Export',
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureRow(
                        icon: Icons.cloud_done_rounded,
                        text: 'Unlimited Cloud Backup & Multi-Device',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Upgrade / Pay Button
                GestureDetector(
                  onTap: () {
                    if (onUpgrade != null) {
                      onUpgrade!();
                    } else {
                      Navigator.of(context).pop(true);
                    }
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
                          const Icon(Icons.lock_open_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Upgrade to Pro — ₹499/mo',
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
                const SizedBox(height: 12),

                // Maybe Later Dismiss
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Maybe Later',
                    style: AppTypography.fontS(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 12, color: AppColors.successGreen),
        ),
        const SizedBox(width: 8),
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

