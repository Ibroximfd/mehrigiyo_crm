import 'package:flutter/material.dart';
import '../../domain/entities/statistics_entity.dart';

class LeadsByStatusChart extends StatelessWidget {
  final List<LeadStatusCountEntity> byStatus;

  const LeadsByStatusChart({super.key, required this.byStatus});

  @override
  Widget build(BuildContext context) {
    if (byStatus.isEmpty) return const SizedBox.shrink();

    final total = byStatus.fold<int>(0, (sum, e) => sum + e.count);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: byStatus.map((item) {
          final percent = total > 0 ? item.count / total : 0.0;
          final color = _colorForIndex(byStatus.indexOf(item));
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StatusRow(
              status: item.status,
              count: item.count,
              percent: percent,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _colorForIndex(int index) {
    const colors = [
      Color(0xFF0D6A55),
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFFD97706),
      Color(0xFFDC2626),
      Color(0xFF0891B2),
      Color(0xFF16A34A),
      Color(0xFFDB2777),
    ];
    return colors[index % colors.length];
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  final int count;
  final double percent;
  final Color color;

  const _StatusRow({
    required this.status,
    required this.count,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count (${(percent * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
