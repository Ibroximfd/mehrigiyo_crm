import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../leads/domain/entities/lead_entity.dart';

/// Fixed width of a kanban column (Bitrix24-style board).
const double kKanbanColumnWidth = 280;

/// Inner width available to a lead card inside a column (column width minus
/// the list's horizontal padding).
const double kKanbanCardWidth = kKanbanColumnWidth - 20;

/// Payload carried by a dragged lead card. Holds just enough to perform an
/// optimistic status change: which lead, and which column it came from.
@immutable
class LeadDragData {
  final int leadId;
  final int fromStatusId;
  const LeadDragData({required this.leadId, required this.fromStatusId});

  @override
  bool operator ==(Object other) =>
      other is LeadDragData &&
      other.leadId == leadId &&
      other.fromStatusId == fromStatusId;

  @override
  int get hashCode => Object.hash(leadId, fromStatusId);
}

/// Visual rendered under the cursor while a lead card is being dragged.
///
/// Per spec: 0.95 scale + raised shadow + 0.85 opacity. Kept deliberately
/// lightweight (no action row, no hover state) so the drag stays smooth.
class LeadDragFeedbackWidget extends StatelessWidget {
  final LeadEntity lead;
  final Color accent;

  const LeadDragFeedbackWidget({
    super.key,
    required this.lead,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.95,
      alignment: Alignment.topLeft,
      child: Opacity(
        opacity: 0.85,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: kKanbanCardWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lead.phone,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed-border placeholder shown in the original slot while a card is being
/// dragged (Draggable.childWhenDragging). Sizes itself to [height] so the
/// column list does not visually collapse during the drag.
class LeadDragPlaceholder extends StatelessWidget {
  final double height;
  const LeadDragPlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primary.withValues(alpha: 0.5),
          radius: 14,
        ),
        child: Center(
          child: Icon(
            Icons.drag_indicator_rounded,
            size: 20,
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
