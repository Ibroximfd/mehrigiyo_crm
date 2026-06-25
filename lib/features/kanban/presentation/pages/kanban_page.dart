import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../leads/domain/entities/lead_entity.dart';
import '../../../operator_chat/domain/usecases/chat_usecases.dart';
import '../bloc/kanban_bloc.dart';
import '../widgets/kanban_column.dart';
class KanbanPage extends StatelessWidget {
  const KanbanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<KanbanBloc, KanbanState>(
        builder: (ctx, state) {
          if (state is KanbanLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is KanbanError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.view_kanban_outlined, size: 64, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => ctx.read<KanbanBloc>().add(const KanbanLoadRequested()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Qayta yuklash'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is KanbanLoaded) {
            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _KanbanHeader(
                      totalLeads: state.leadsByStatus.values.fold(0, (a, b) => a + b.length),
                      isMoving: state.isMoving,
                      onRefresh: () => ctx.read<KanbanBloc>().add(const KanbanLoadRequested()),
                      onAdd: () => _showCreateDialog(ctx, state),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async =>
                            ctx.read<KanbanBloc>().add(const KanbanLoadRequested()),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: SizedBox(
                            height: double.infinity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: state.statuses.map((s) {
                                final leads = state.leadsByStatus[s.id] ?? [];
                                return KanbanColumn(
                                  status: s,
                                  leads: leads,
                                  allStatuses: state.statuses,
                                  onStatusChange: (leadId, newStatusId, oldStatusId) {
                                    ctx.read<KanbanBloc>().add(KanbanLeadStatusChanged(
                                      leadId: leadId,
                                      newStatusId: newStatusId,
                                      oldStatusId: oldStatusId,
                                    ));
                                  },
                                  onLeadTap: (leadId) => ctx.push(RouteNames.sellerLeadDetail(leadId)),
                                  onChatTap: (lead) => _openChat(ctx, lead),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.isMoving)
                  const Positioned(
                    top: 0, left: 0, right: 0,
                    child: LinearProgressIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                    ),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _openChat(BuildContext context, LeadEntity lead) async {
    // useRootNavigator: true — go_router nested navigators bilan conflict bo'lmasin
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final result = await GetIt.I<CreateChatRoomUseCase>()(
      phone: lead.phone,
      leadId: lead.id,
    );

    if (!context.mounted) return;

    // Root navigator orqali dialog yopiladi
    Navigator.of(context, rootNavigator: true).pop();

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(f.message),
        backgroundColor: AppColors.error,
      )),
      (room) => context.push(
        RouteNames.sellerChatRoom(room.id),
        extra: {
          'name': room.participantName,
          'phone': room.participantPhone,
          'leadId': lead.id,
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, KanbanLoaded state) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<KanbanBloc>(),
        child: _CreateLeadKanbanDialog(statuses: state.statuses),
      ),
    );
  }
}

class _KanbanHeader extends StatelessWidget {
  final int totalLeads;
  final bool isMoving;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const _KanbanHeader({
    required this.totalLeads,
    required this.isMoving,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Board',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '$totalLeads ta mijoz',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Yangilash',
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Yangi'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateLeadKanbanDialog extends StatefulWidget {
  final List<dynamic> statuses;
  const _CreateLeadKanbanDialog({required this.statuses});

  @override
  State<_CreateLeadKanbanDialog> createState() => _CreateLeadKanbanDialogState();
}

class _CreateLeadKanbanDialogState extends State<_CreateLeadKanbanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  int? _selectedStatusId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final defaultStatus = widget.statuses.cast<dynamic>().firstWhere(
      (s) => s.isDefault == true,
      orElse: () => widget.statuses.isNotEmpty ? widget.statuses.first : null,
    );
    _selectedStatusId = defaultStatus?.id as int?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _regionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    context.read<KanbanBloc>().add(KanbanCreateLead(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      region: _regionCtrl.text.trim().isEmpty ? null : _regionCtrl.text.trim(),
      statusId: _selectedStatusId,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Yangi mijoz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ism *', prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Kiritilishi shart' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon *', prefixIcon: Icon(Icons.phone_rounded),
                    hintText: '998901234567',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Kiritilishi shart' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hudud (ixtiyoriy)', prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.statuses.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: _selectedStatusId,
                    decoration: const InputDecoration(labelText: 'Ustun'),
                    items: widget.statuses.cast<dynamic>().map<DropdownMenuItem<int>>((s) =>
                      DropdownMenuItem<int>(value: s.id as int, child: Text(s.name as String))
                    ).toList(),
                    onChanged: (v) => setState(() => _selectedStatusId = v),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Qo\'shish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
