import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _StatusStyle {
  final Color bg;
  final Color text;
  final Color border;
  final IconData icon;
  final String label;

  const _StatusStyle({
    required this.bg,
    required this.text,
    required this.border,
    required this.icon,
    required this.label,
  });
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  static const _defaultStyle = _StatusStyle(
    bg: AppColors.warningAmberBg,
    text: AppColors.warningAmber,
    border: AppColors.warningBorder,
    icon: Icons.error_rounded,
    label: 'Needs Review',
  );

  static const Map<String, _StatusStyle> _styles = {
    'APPROVED': _StatusStyle(
      bg: AppColors.successBadgeBg,
      text: AppColors.successBadgeText,
      border: AppColors.successBadgeBorder,
      icon: Icons.check_circle_rounded,
      label: 'Approved',
    ),
    'POSTED': _StatusStyle(
      bg: AppColors.postedTealBg,
      text: AppColors.postedTealText,
      border: AppColors.postedTealBorder,
      icon: Icons.verified_rounded,
      label: 'Posted',
    ),
    'POST_FAILED': _StatusStyle(
      bg: AppColors.errorRedBg,
      text: AppColors.errorRed,
      border: AppColors.errorRed,
      icon: Icons.error_outline_rounded,
      label: 'Post Failed',
    ),
    'NEEDS_CORRECTION': _StatusStyle(
      bg: AppColors.warningOrangeBg,
      text: AppColors.orange,
      border: AppColors.warningOrangeBorder,
      icon: Icons.edit_note_rounded,
      label: 'Needs Correction',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[status.toUpperCase()] ?? _defaultStyle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: style.border.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.text),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
