import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/consultation_entity.dart';
import '../../../../core/theme/app_colors.dart';
import 'status_badge.dart';

class DesktopConsultationsTable extends StatelessWidget {
  final List<ConsultationEntity> items;
  final bool isRefreshing;
  final bool isLoadingMore;
  final ValueChanged<ConsultationEntity> onTap;
  final ScrollController? scrollController;

  const DesktopConsultationsTable({
    super.key,
    required this.items,
    required this.isRefreshing,
    required this.onTap,
    this.isLoadingMore = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: items.isEmpty
              ? const _EmptyView()
              : Column(
                  children: [
                    _TableHeader(),
                    Expanded(
                      child: _TableRows(
                        items: items,
                        onTap: onTap,
                        isLoadingMore: isLoadingMore,
                        scrollController: scrollController,
                      ),
                    ),
                  ],
                ),
        ),
        if (isRefreshing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Arizalar topilmadi',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: const [
          SizedBox(width: 50, child: _HeaderCell(text: '№')),
          SizedBox(width: 16),
          Expanded(flex: 2, child: _HeaderCell(text: 'Mijoz')),
          SizedBox(width: 16),
          Expanded(flex: 2, child: _HeaderCell(text: 'Muammo / Savol')),
          SizedBox(width: 16),
          Expanded(flex: 2, child: _HeaderCell(text: 'Operator izohi')),
          SizedBox(width: 16),
          SizedBox(width: 130, child: _HeaderCell(text: 'Holat')),
          SizedBox(width: 16),
          SizedBox(width: 100, child: _HeaderCell(text: 'Sana')),
          SizedBox(width: 16),
          SizedBox(width: 120, child: _HeaderCell(text: 'Amallar')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
    );
  }
}

class _TableRows extends StatelessWidget {
  final List<ConsultationEntity> items;
  final ValueChanged<ConsultationEntity> onTap;
  final bool isLoadingMore;
  final ScrollController? scrollController;

  const _TableRows({
    required this.items,
    required this.onTap,
    this.isLoadingMore = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.length + (isLoadingMore ? 1 : 0);
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      itemCount: total,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        final item = items[index];
        return _TableRow(item: item, onTap: () => onTap(item));
      },
    );
  }
}

class _TableRow extends StatelessWidget {
  final ConsultationEntity item;
  final VoidCallback onTap;

  const _TableRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              item.id,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                _PhoneCopyCell(phone: item.phone),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: item.issueDescription,
              child: Text(
                item.issueDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: item.operatorNote != null && item.operatorNote!.isNotEmpty
                ? Tooltip(
                    message: item.operatorNote!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        item.operatorNote!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  )
                : const Text(
                    'Izoh yo\'q',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 130,
            child: StatusBadge(status: item.status),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd.MM.yyyy').format(item.createdAt),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm').format(item.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: TextButton.icon(
              icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
              label: const Text('Batafsil'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneCopyCell extends StatelessWidget {
  final String phone;
  const _PhoneCopyCell({required this.phone});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: phone));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telefon raqami nusxalandi!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              phone,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.copy_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
