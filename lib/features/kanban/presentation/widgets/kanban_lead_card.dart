import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../leads/domain/entities/lead_entity.dart';
import '../../../statuses/domain/entities/status_entity.dart';

class KanbanLeadCard extends StatelessWidget {
  final LeadEntity lead;
  final List<StatusEntity> allStatuses;
  final void Function(int newStatusId) onStatusChange;
  final VoidCallback? onTap;

  const KanbanLeadCard({
    super.key,
    required this.lead,
    required this.allStatuses,
    required this.onStatusChange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lead.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_rounded, size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    lead.phone,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (lead.region != null && lead.region!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      lead.region!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SourceBadge(source: lead.source),
                GestureDetector(
                  onTap: () => _showMoveMenu(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 13, color: AppColors.primary),
                        SizedBox(width: 3),
                        Text('Ko\'chirish', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveMenu(BuildContext context) {
    final otherStatuses = allStatuses.where((s) => s.id != lead.statusId).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${lead.fullName} — ko\'chirish',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            const Text('Yangi statusni tanlang:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 12),
            ...otherStatuses.map(
              (s) => ListTile(
                dense: true,
                leading: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: _hexColor(s.color),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(context).pop();
                  onStatusChange(s.id);
                },
              ),
            ),
            if (otherStatuses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Boshqa statuslar yo\'q', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    const map = {
      'manual': ('Qo\'lda', AppColors.accent),
      'app': ('Ilova', AppColors.primary),
      'instagram': ('IG', Color(0xFFE1306C)),
      'facebook': ('FB', Color(0xFF1877F2)),
    };
    final entry = map[source] ?? ('?', Color(0xFF94A3B8));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: entry.$2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        entry.$1,
        style: TextStyle(color: entry.$2, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
