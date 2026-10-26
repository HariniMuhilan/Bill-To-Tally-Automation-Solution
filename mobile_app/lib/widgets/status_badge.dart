import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    IconData icon;
    String label = status;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        bg = AppColors.successBg;
        text = const Color(0xFF285C3A); // Deep sage
        icon = Icons.check_circle_rounded;
        break;
      case 'POSTED':
        bg = const Color(0x289CB9A6);
        text = const Color(0xFF202A27);
        icon = Icons.verified_rounded;
        break;
      case 'POST_FAILED':
        bg = AppColors.errorRedBg;
        text = AppColors.errorRed;
        icon = Icons.error_outline_rounded;
        break;
      case 'NEEDS_CORRECTION':
        bg = AppColors.mauveBg;
        text = AppColors.mutedMauve;
        icon = Icons.edit_note_rounded;
        break;
      case 'NEEDS_REVIEW':
      default:
        bg = AppColors.mauveBg;
        text = AppColors.mutedMauve;
        icon = Icons.schedule_rounded;
        label = 'NEEDS_REVIEW';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
