import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/status_entity.dart';

/// Shows a centered dialog for picking a new status for a lead.
///
/// Behaviour:
/// - Tapping a status auto-closes the dialog and fires [onSelected].
/// - Tapping outside the dialog (barrier) dismisses it.
/// - There is an explicit close (X) button as well.
Future<void> showStatusPickerDialog({
  required BuildContext context,
  required String leadName,
  required int? currentStatusId,
  required List<StatusEntity> statuses,
  required void Function(int statusId) onSelected,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _StatusPickerDialog(
      leadName: leadName,
      currentStatusId: currentStatusId,
      statuses: statuses,
      onSelected: onSelected,
    ),
  );
}

class _StatusPickerDialog extends StatelessWidget {
  final String leadName;
  final int? currentStatusId;
  final List<StatusEntity> statuses;
  final void Function(int statusId) onSelected;

  const _StatusPickerDialog({
    required this.leadName,
    required this.currentStatusId,
    required this.statuses,
    required this.onSelected,
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
    final others = statuses.where((s) => s.id != currentStatusId).toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status o\'zgartirish',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          leadName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Yopish',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: others.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 20,
                      ),
                      child: Center(
                        child: Text(
                          'Boshqa statuslar yo\'q',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: others.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 52),
                      itemBuilder: (_, i) {
                        final s = others[i];
                        return ListTile(
                          leading: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _hexColor(s.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFFCBD5E1),
                          ),
                          onTap: () {
                            // Auto-close, then notify the caller.
                            Navigator.of(context).pop();
                            onSelected(s.id);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
