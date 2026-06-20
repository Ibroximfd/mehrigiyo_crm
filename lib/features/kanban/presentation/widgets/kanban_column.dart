import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../leads/domain/entities/lead_entity.dart';
import '../../../statuses/domain/entities/status_entity.dart';
import 'kanban_lead_card.dart';

class KanbanColumn extends StatelessWidget {
  final StatusEntity status;
  final List<LeadEntity> leads;
  final List<StatusEntity> allStatuses;
  final void Function(int leadId, int newStatusId, int oldStatusId) onStatusChange;
  final void Function(int leadId) onLeadTap;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.leads,
    required this.allStatuses,
    required this.onStatusChange,
    required this.onLeadTap,
  });

  Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = _hexColor(status.color);
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: col.withValues(alpha: 1),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${leads.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: col.withValues(alpha: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cards
          Expanded(
            child: leads.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded, size: 32, color: col.withValues(alpha: 0.3)),
                          const SizedBox(height: 6),
                          Text(
                            'Bo\'sh',
                            style: TextStyle(
                              fontSize: 12,
                              color: col.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: leads.length,
                    itemBuilder: (_, i) => KanbanLeadCard(
                      lead: leads[i],
                      allStatuses: allStatuses,
                      onStatusChange: (newId) => onStatusChange(leads[i].id, newId, status.id),
                      onTap: () => onLeadTap(leads[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
