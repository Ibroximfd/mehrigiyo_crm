import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, setEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../leads/domain/entities/lead_entity.dart';
import '../../../statuses/domain/entities/status_entity.dart';
import '../../../operator_chat/domain/usecases/chat_usecases.dart';
import '../bloc/kanban_bloc.dart';
import '../widgets/kanban_column.dart';
import '../widgets/lead_drag_feedback_widget.dart';
class KanbanPage extends StatelessWidget {
  const KanbanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocConsumer<KanbanBloc, KanbanState>(
        listenWhen: (_, curr) => curr is KanbanMoveFailure,
        listener: (ctx, state) {
          if (state is KanbanMoveFailure) {
            ScaffoldMessenger.of(ctx)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ));
          }
        },
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
            return _KanbanBoard(
              state: state,
              onRefresh: () => ctx.read<KanbanBloc>().add(KanbanLoadRequested(
                category: state.category,
                statusIds: state.selectedStatusIds.toList(),
              )),
              onFilterChanged: (category, statusIds) =>
                  ctx.read<KanbanBloc>().add(KanbanLoadRequested(
                    category: category,
                    statusIds: statusIds.toList(),
                  )),
              onAdd: () => _showCreateDialog(ctx, state),
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
          // Fall back to the lead's own name/phone when the chat room has no
          // client name (e.g. client registered with phone only).
          'name': room.participantName.isNotEmpty ? room.participantName : lead.fullName,
          'phone': room.participantPhone.isNotEmpty ? room.participantPhone : lead.phone,
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

/// Horizontally-scrollable board. Owns the shared drag payload (so every valid
/// column can highlight on drag start) and a horizontal scroll controller wired
/// to mouse-wheel input. Stateful only to manage those two resources.
class _KanbanBoard extends StatefulWidget {
  final KanbanLoaded state;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;
  final void Function(String? category, Set<int> statusIds) onFilterChanged;
  final void Function(int leadId, int newStatusId, int oldStatusId) onStatusChange;
  final void Function(int leadId) onLeadTap;
  final void Function(LeadEntity lead) onChatTap;

  const _KanbanBoard({
    required this.state,
    required this.onRefresh,
    required this.onAdd,
    required this.onFilterChanged,
    required this.onStatusChange,
    required this.onLeadTap,
    required this.onChatTap,
  });

  @override
  State<_KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<_KanbanBoard> {
  final ValueNotifier<LeadDragData?> _activeDrag = ValueNotifier(null);
  final ScrollController _hCtrl = ScrollController();

  @override
  void dispose() {
    _activeDrag.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  // Translate a vertical mouse wheel into horizontal board scrolling. Using the
  // pointer-signal resolver means an inner (vertical) column list registers
  // first and wins when hovered — so card lists still scroll vertically.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_hCtrl.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      final scroll = e as PointerScrollEvent;
      final delta = scroll.scrollDelta.dy != 0
          ? scroll.scrollDelta.dy
          : scroll.scrollDelta.dx;
      final target = (_hCtrl.offset + delta).clamp(
        _hCtrl.position.minScrollExtent,
        _hCtrl.position.maxScrollExtent,
      );
      if (target != _hCtrl.offset) _hCtrl.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final dragEnabled = kIsWeb;
    final visibleStatuses = state.visibleStatuses;
    final totalLeads = visibleStatuses.fold<int>(
      0,
      (a, s) => a + (state.leadsByStatus[s.id]?.length ?? 0),
    );

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KanbanHeader(
              totalLeads: totalLeads,
              isMoving: state.isMoving,
              onRefresh: widget.onRefresh,
              onAdd: widget.onAdd,
            ),
            _KanbanFilterBar(
              statuses: state.statuses,
              category: state.category,
              selectedStatusIds: state.selectedStatusIds,
              onChanged: widget.onFilterChanged,
            ),
            Expanded(
              child: visibleStatuses.isEmpty
                  ? const Center(
                      child: Text(
                        'Tanlangan filtrda ustun yo\'q',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async => widget.onRefresh(),
                      child: Listener(
                        onPointerSignal: _onPointerSignal,
                        child: SingleChildScrollView(
                          controller: _hCtrl,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: SizedBox(
                            height: double.infinity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: visibleStatuses.map((s) {
                                final leads = state.leadsByStatus[s.id] ?? const [];
                                return KanbanColumn(
                                  key: ValueKey(s.id),
                                  status: s,
                                  leads: leads,
                                  allStatuses: state.statuses,
                                  dragEnabled: dragEnabled,
                                  activeDrag: _activeDrag,
                                  onStatusChange: widget.onStatusChange,
                                  onDragStateChanged: (d) => _activeDrag.value = d,
                                  onLeadTap: widget.onLeadTap,
                                  onChatTap: widget.onChatTap,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        if (state.isMoving || state.isFiltering)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.primaryLight,
            ),
          ),
      ],
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

/// Server-side status filter for the board. Category selector (Hammasi / Sotuv /
/// Sotuvdan keyin) plus multi-select status chips. Selection is kept locally for
/// instant chip feedback and the actual reload is debounced so rapid taps issue
/// a single request (`?category=post_sale&status=5,6`).
class _KanbanFilterBar extends StatefulWidget {
  final List<StatusEntity> statuses;
  final String? category;
  final Set<int> selectedStatusIds;
  final void Function(String? category, Set<int> statusIds) onChanged;

  const _KanbanFilterBar({
    required this.statuses,
    required this.category,
    required this.selectedStatusIds,
    required this.onChanged,
  });

  @override
  State<_KanbanFilterBar> createState() => _KanbanFilterBarState();
}

class _KanbanFilterBarState extends State<_KanbanFilterBar> {
  late String? _category = widget.category;
  late Set<int> _selected = {...widget.selectedStatusIds};
  Timer? _debounce;

  static const _categories = <String?, String>{
    null: 'Hammasi',
    'sales': 'Sotuv',
    'post_sale': 'Sotuvdan keyin',
  };

  @override
  void didUpdateWidget(covariant _KanbanFilterBar old) {
    super.didUpdateWidget(old);
    // Resync from the committed state when no edit is pending (e.g. after a
    // refresh) so the chips never drift from what the board is actually showing.
    if (_debounce?.isActive != true &&
        (widget.category != _category ||
            !setEquals(widget.selectedStatusIds, _selected))) {
      _category = widget.category;
      _selected = {...widget.selectedStatusIds};
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _dispatch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(_category, _selected);
    });
  }

  void _selectCategory(String? category) {
    if (_category == category) return;
    setState(() {
      _category = category;
      _selected = {}; // statuses differ per category — reset the selection
    });
    _dispatch();
  }

  void _toggleStatus(int id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
    _dispatch();
  }

  Color _statusColor(StatusEntity s) {
    final h = s.color.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _category == null
        ? widget.statuses
        : widget.statuses.where((s) => s.category == _category).toList();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.entries.map((e) {
                final selected = _category == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) => _selectCategory(e.key),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          if (statuses.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((s) {
                  final selected = _selected.contains(s.id);
                  final col = _statusColor(s);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.name),
                      selected: selected,
                      onSelected: (_) => _toggleStatus(s.id),
                      avatar: CircleAvatar(backgroundColor: col, radius: 6),
                      selectedColor: col.withValues(alpha: 0.18),
                      checkmarkColor: col,
                      labelStyle: TextStyle(
                        color: selected ? col : const Color(0xFF475569),
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      backgroundColor: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: selected ? col : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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
