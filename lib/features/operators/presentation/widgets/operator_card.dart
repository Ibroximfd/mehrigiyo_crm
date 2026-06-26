import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/operator_entity.dart';

class OperatorCard extends StatelessWidget {
  final OperatorEntity operator;
  final VoidCallback? onEdit;
  const OperatorCard({super.key, required this.operator, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: operator.isAdmin
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.primaryLight,
          child: Text(
            operator.fullName.isNotEmpty
                ? operator.fullName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: operator.isAdmin ? AppColors.gold : AppColors.primary,
            ),
          ),
        ),
        title: Text(
          operator.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.alternate_email_rounded, size: 12, color: Color(0xFF94A3B8)),
            const SizedBox(width: 3),
            Text(
              operator.username,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge(
                  label: operator.isAdmin ? 'Admin' : 'Sotuvchi',
                  color: operator.isAdmin ? AppColors.gold : AppColors.accent,
                ),
                const SizedBox(height: 4),
                Text(
                  '${operator.commissionPercent}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF94A3B8)),
                tooltip: 'Tahrirlash',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
