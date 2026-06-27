import 'package:flutter/material.dart';
import '../../../../core/utils/money_format.dart';
import '../../domain/entities/statistics_entity.dart';

/// Buyurtma bosqichlari (order_pipeline) — jarayonda / yetkazilgan / bekor qilingan,
/// har biri soni va summasi bilan, hamda jami yakuni.
class OrderPipelineCard extends StatelessWidget {
  final OrderPipelineEntity pipeline;
  const OrderPipelineCard({super.key, required this.pipeline});

  @override
  Widget build(BuildContext context) {
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
        children: [
          _PipelineRow(
            icon: Icons.sync_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            label: 'Jarayonda',
            stage: pipeline.inProgress,
          ),
          const SizedBox(height: 12),
          _PipelineRow(
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
            label: 'Yetkazilgan',
            stage: pipeline.delivered,
          ),
          const SizedBox(height: 12),
          _PipelineRow(
            icon: Icons.cancel_outlined,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEE2E2),
            label: 'Bekor qilingan',
            stage: pipeline.cancelled,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Jami buyurtma',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                '${pipeline.totalOrders} ta',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatSom(pipeline.totalAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D6A55),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;
  final PipelineStageEntity stage;

  const _PipelineRow({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${stage.count} ta',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          formatSom(stage.amount),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
