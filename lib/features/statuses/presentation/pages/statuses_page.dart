import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/statuses_bloc.dart';
import '../widgets/create_status_dialog.dart';

class StatusesPage extends StatelessWidget {
  const StatusesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocListener<StatusesBloc, StatusesState>(
        listenWhen: (_, s) => s is StatusMutateError,
        listener: (ctx, state) {
          if (state is StatusMutateError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async =>
              context.read<StatusesBloc>().add(const StatusesLoadRequested()),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statuslar',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Board ustunlari',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCreate(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Yangi'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<StatusesBloc, StatusesState>(
                builder: (ctx, state) {
                  if (state is StatusesLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  }
                  if (state is StatusesError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(state.message, style: const TextStyle(color: Color(0xFF64748B))),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => ctx.read<StatusesBloc>().add(const StatusesLoadRequested()),
                              child: const Text('Qayta yuklash'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final statuses = state is StatusesLoaded
                      ? state.statuses
                      : state is StatusMutating
                          ? state.statuses
                          : state is StatusMutateError
                              ? state.statuses
                              : <dynamic>[];

                  if (statuses.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_kanban_outlined, size: 56, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'Statuslar yo\'q',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final salesList = statuses.where((s) => s.category == 'sales').toList();
                  final postSaleList = statuses.where((s) => s.category == 'post_sale').toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (salesList.isNotEmpty) ...[
                          _SectionHeader(title: 'Sotuv bosqichi (${salesList.length})'),
                          ...salesList.map((s) => _StatusTile(
                            status: s,
                            loading: state is StatusMutating,
                            onDelete: () => ctx.read<StatusesBloc>().add(StatusDeleteRequested(s.id)),
                          )),
                          const SizedBox(height: 8),
                        ],
                        if (postSaleList.isNotEmpty) ...[
                          _SectionHeader(title: 'Sotuv keyin (${postSaleList.length})'),
                          ...postSaleList.map((s) => _StatusTile(
                            status: s,
                            loading: state is StatusMutating,
                            onDelete: () => ctx.read<StatusesBloc>().add(StatusDeleteRequested(s.id)),
                          )),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<StatusesBloc>(),
        child: const CreateStatusDialog(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final dynamic status;
  final bool loading;
  final VoidCallback onDelete;
  const _StatusTile({required this.status, required this.loading, required this.onDelete});

  Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Statusni o\'chirish',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
            children: [
              const TextSpan(text: '"'),
              TextSpan(
                text: status.name as String,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const TextSpan(
                text: '" statusini o\'chirmoqchimisiz?\nBu amalni qaytarib bo\'lmaydi.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE8ECF0)),
      ),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 36,
          decoration: BoxDecoration(
            color: _hexColor(status.color as String),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          status.name as String,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
        subtitle: Text(
          'Tartib: ${status.order}${status.isDefault ? ' • Default' : ''}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                tooltip: 'O\'chirish',
              ),
      ),
    );
  }
}
