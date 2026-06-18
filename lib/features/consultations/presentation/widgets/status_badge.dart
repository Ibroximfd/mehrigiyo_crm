import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final int status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;

    switch (status) {
      case 1:
        color = AppColors.statusNew;
        text = 'Yangi';
      case 2:
        color = AppColors.statusInProgress;
        text = 'Jarayonda';
      case 3:
        color = AppColors.statusCompleted;
        text = 'Tugallangan';
      default:
        color = Colors.grey;
        text = 'Noma\'lum';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
