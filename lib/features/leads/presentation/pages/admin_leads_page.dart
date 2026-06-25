import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../operators/domain/entities/operator_entity.dart';
import '../bloc/admin_leads_bloc.dart';
import '../widgets/bulk_create_leads_dialog.dart';
import '../widgets/lead_card.dart';

class AdminLeadsPage extends StatelessWidget {
  final List<OperatorEntity> operators;
  const AdminLeadsPage({super.key, required this.operators});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocConsumer<AdminLeadsBloc, AdminLeadsState>(
        listenWhen: (_, s) => s is AdminLeadsAssigned || s is AdminLeadsBulkCreated || s is AdminLeadsError,
        listener: (ctx, state) {
          if (state is AdminLeadsAssigned) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('${state.count} ta lead biriktirildi'),
              backgroundColor: AppColors.success,
            ));
          } else if (state is AdminLeadsBulkCreated) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('${state.count} ta lead muvaffaqiyatli qo\'shildi'),
              backgroundColor: AppColors.success,
            ));
          } else if (state is AdminLeadsError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (ctx, state) {
          final isAssigning = state is AdminLeadsAssigning;
          final leads = state is AdminLeadsLoaded
              ? state.leads
              : state is AdminLeadsAssigning
                  ? state.leads
                  : <dynamic>[];
          final selected = state is AdminLeadsLoaded ? state.selectedIds : <int>{};

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ctx.read<AdminLeadsBloc>().add(const AdminLeadsLoadRequested()),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Barcha Leadlar',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    'Filialingizdagi barcha mijozlar',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => showDialog(
                                context: ctx,
                                builder: (_) => BlocProvider.value(
                                  value: ctx.read<AdminLeadsBloc>(),
                                  child: const BulkCreateLeadsDialog(),
                                ),
                              ),
                              icon: const Icon(Icons.upload_rounded, size: 16),
                              label: const Text('Ko\'p qo\'shish'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (selected.isNotEmpty)
                              _AssignButton(
                                count: selected.length,
                                operators: operators,
                                onAssign: (opId) {
                                  ctx.read<AdminLeadsBloc>().add(AdminLeadsAssignRequested(
                                    leadIds: selected.toList(),
                                    operatorId: opId,
                                  ));
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (selected.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${selected.length} ta tanlandi',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => ctx.read<AdminLeadsBloc>().add(
                                    const AdminLeadSelectionCleared(),
                                  ),
                                  child: const Text(
                                    'Bekor qilish',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _FilterRow(operators: operators),
                      ],
                    ),
                  ),
                ),
                if (state is AdminLeadsLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (state is AdminLeadsError)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(state.message, style: const TextStyle(color: Color(0xFF64748B))),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => ctx.read<AdminLeadsBloc>().add(
                              const AdminLeadsLoadRequested(),
                            ),
                            child: const Text('Qayta yuklash'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          if (i == leads.length) {
                            final hasMore = state is AdminLeadsLoaded && state.hasMore;
                            return hasMore
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: OutlinedButton(
                                        onPressed: () => ctx.read<AdminLeadsBloc>().add(
                                          const AdminLeadsLoadMore(),
                                        ),
                                        child: const Text('Ko\'proq'),
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 80);
                          }
                          if (leads.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(
                                child: Text(
                                  'Leadlar topilmadi',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                                ),
                              ),
                            );
                          }
                          final lead = leads[i];
                          final isSelected = selected.contains(lead.id);
                          return isAssigning && isSelected
                              ? const SizedBox.shrink()
                              : LeadCard(
                                  lead: lead,
                                  isSelected: isSelected,
                                  onTap: () => ctx.read<AdminLeadsBloc>().add(
                                    AdminLeadSelectionToggled(lead.id),
                                  ),
                                  onSelectionToggle: () => ctx.read<AdminLeadsBloc>().add(
                                    AdminLeadSelectionToggled(lead.id),
                                  ),
                                );
                        },
                        childCount: leads.isEmpty ? 1 : leads.length + 1,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatefulWidget {
  final List<OperatorEntity> operators;
  const _FilterRow({required this.operators});

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  OperatorEntity? _selected;

  void _openPicker(BuildContext context) {
    final sellers = widget.operators.where((o) => !o.isAdmin).toList();
    if (sellers.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Operatorni tanlang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: sellers.map((op) {
                    final isActive = _selected?.id == op.id;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isActive
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        child: Text(
                          op.fullName[0].toUpperCase(),
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        op.fullName,
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? AppColors.primary
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.primary, size: 18)
                          : null,
                      onTap: () {
                        setState(() => _selected = op);
                        Navigator.of(ctx, rootNavigator: true).pop();
                        context.read<AdminLeadsBloc>().add(
                          AdminLeadsLoadRequested(assignedTo: op.id),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(ctx, rootNavigator: true).pop(),
                  child: const Text('Bekor qilish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelected = _selected != null;
    return Row(
      children: [
        _FilterChip(
          label: 'Barchasi',
          selected: !hasSelected,
          onTap: () {
            setState(() => _selected = null);
            context.read<AdminLeadsBloc>().add(const AdminLeadsLoadRequested());
          },
        ),
        const SizedBox(width: 8),
        // Operator dropdown chip
        GestureDetector(
          onTap: () => _openPicker(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: hasSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasSelected ? _selected!.fullName : 'Operator',
                  style: TextStyle(
                    color: hasSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: hasSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AssignButton extends StatelessWidget {
  final int count;
  final List<OperatorEntity> operators;
  final void Function(int operatorId) onAssign;

  const _AssignButton({
    required this.count,
    required this.operators,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showAssignSheet(context),
      icon: const Icon(Icons.assignment_ind_rounded, size: 16),
      label: Text('Biriktirish ($count)'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAssignSheet(BuildContext context) {
    final sellers = operators.where((o) => !o.isAdmin).toList();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operatorni tanlang',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ta lead biriktiriladi',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                  ],
                ),
              ),
              if (sellers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('Sotuvchi operatorlar yo\'q',
                        style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: sellers
                        .map((op) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(op.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                              ),
                              title: Text(op.fullName),
                              subtitle: Text('${op.commissionPercent}% komissiya'),
                              onTap: () {
                                Navigator.of(context, rootNavigator: true).pop();
                                onAssign(op.id);
                              },
                            ))
                        .toList(),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: TextButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text('Bekor qilish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
