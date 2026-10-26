import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;
    IconData icon;
    String label = status;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF1B5E20);
        border = const Color(0xFF81C784).withOpacity(0.4);
        icon = Icons.check_circle_rounded;
        label = 'Approved';
        break;
      case 'POSTED':
        bg = const Color(0xFFE0F2F1);
        text = const Color(0xFF004D40);
        border = const Color(0xFF4DB6AC).withOpacity(0.4);
        icon = Icons.verified_rounded;
        label = 'Posted';
        break;
      case 'POST_FAILED':
        bg = AppColors.errorRedBg;
        text = AppColors.errorRed;
        border = AppColors.errorRed.withOpacity(0.3);
        icon = Icons.error_outline_rounded;
        label = 'Post Failed';
        break;
      case 'NEEDS_CORRECTION':
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFE65100);
        border = const Color(0xFFFFB74D).withOpacity(0.4);
        icon = Icons.edit_note_rounded;
        label = 'Needs Correction';
        break;
      case 'NEEDS_REVIEW':
      default:
        bg = const Color(0xFFFEF3EB);
        text = const Color(0xFFB45309);
        border = const Color(0xFFF59E0B).withOpacity(0.35);
        icon = Icons.error_rounded;
        label = 'Needs Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
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
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
