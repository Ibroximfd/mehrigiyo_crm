import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../leads/domain/entities/lead_entity.dart';
import '../../../statuses/domain/entities/status_entity.dart';
import 'kanban_lead_card.dart';
import 'lead_drag_feedback_widget.dart';

class KanbanColumn extends StatefulWidget {
  final StatusEntity status;
  final List<LeadEntity> leads;
  final List<StatusEntity> allStatuses;
  final bool dragEnabled;

  /// Active drag payload across the whole board (null when nothing is dragging).
  /// Used to pre-highlight every column that can accept the dragged card.
  final ValueListenable<LeadDragData?> activeDrag;

  final void Function(int leadId, int newStatusId, int oldStatusId) onStatusChange;
  final void Function(LeadDragData? data) onDragStateChanged;
  final void Function(int leadId) onLeadTap;
  final void Function(LeadEntity lead) onChatTap;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.leads,
    required this.allStatuses,
    required this.dragEnabled,
    required this.activeDrag,
    required this.onStatusChange,
    required this.onDragStateChanged,
    required this.onLeadTap,
    required this.onChatTap,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn>
    with SingleTickerProviderStateMixin {
  final ScrollController _listCtrl = ScrollController();
  final GlobalKey _listKey = GlobalKey();

  late final AnimationController _flashCtrl;
  Timer? _autoScroll;

  static const double _edgeZone = 64; // px from top/bottom that triggers scroll
  static const double _scrollStep = 14; // px per tick

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _flashCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Color get _col {
    final h = widget.status.color.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  // ── Auto-scroll while dragging near the column edges ──────────────────────
  void _handleDragMove(Offset globalPointer) {
    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_listCtrl.hasClients) return;
    final local = box.globalToLocal(globalPointer).dy;
    final height = box.size.height;

    if (local < _edgeZone) {
      _startAutoScroll(-_scrollStep);
    } else if (local > height - _edgeZone) {
      _startAutoScroll(_scrollStep);
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll(double delta) {
    if (_autoScroll != null) return;
    _autoScroll = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_listCtrl.hasClients) return;
      final target = (_listCtrl.offset + delta)
          .clamp(_listCtrl.position.minScrollExtent, _listCtrl.position.maxScrollExtent);
      if (target != _listCtrl.offset) _listCtrl.jumpTo(target);
    });
  }

  void _stopAutoScroll() {
    _autoScroll?.cancel();
    _autoScroll = null;
  }

  @override
  Widget build(BuildContext context) {
    final col = _col;

    // RepaintBoundary: isolates this column so a rebuild/repaint in one column
    // (e.g. drag highlight, flash) never repaints its neighbours.
    return RepaintBoundary(
      child: DragTarget<LeadDragData>(
        onWillAcceptWithDetails: (details) =>
            details.data.fromStatusId != widget.status.id,
        onMove: (details) => _handleDragMove(details.offset),
        onLeave: (_) => _stopAutoScroll(),
        onAcceptWithDetails: (details) {
          _stopAutoScroll();
          _flashCtrl.forward(from: 0);
          widget.onStatusChange(
            details.data.leadId,
            widget.status.id,
            details.data.fromStatusId,
          );
        },
        builder: (context, candidate, rejected) {
          final isHovering = candidate.isNotEmpty;
          return ValueListenableBuilder<LeadDragData?>(
            valueListenable: widget.activeDrag,
            builder: (context, drag, child) {
              final isValidTarget =
                  drag != null && drag.fromStatusId != widget.status.id;
              return AnimatedBuilder(
                animation: _flashCtrl,
                builder: (context, _) => _decoratedColumn(
                  col: col,
                  isHovering: isHovering,
                  isValidTarget: isValidTarget,
                  flash: _flashCtrl.value,
                  child: child!,
                ),
              );
            },
            // Built once and reused across highlight/flash rebuilds.
            child: _columnBody(col),
          );
        },
      ),
    );
  }

  Widget _decoratedColumn({
    required Color col,
    required bool isHovering,
    required bool isValidTarget,
    required double flash,
    required Widget child,
  }) {
    final Color borderColor;
    final double borderWidth;
    Color background = col.withValues(alpha: 0.05);

    if (isHovering) {
      borderColor = AppColors.primary;
      borderWidth = 2;
      background = AppColors.primary.withValues(alpha: 0.08);
    } else if (isValidTarget) {
      borderColor = AppColors.primary.withValues(alpha: 0.45);
      borderWidth = 1.5;
    } else {
      borderColor = col.withValues(alpha: 0.2);
      borderWidth = 1;
    }

    // Drop-accepted flash: green at the instant of drop (flash≈0), fading back
    // to the column's normal background as the 300ms animation completes.
    if (flash > 0) {
      background = Color.lerp(
        const Color(0xFF22C55E).withValues(alpha: 0.28),
        background,
        flash,
      )!;
    }

    return Container(
      width: kKanbanColumnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );
  }

  Widget _columnBody(Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: col, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.status.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: col,
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
                  '${widget.leads.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: col,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Cards
        Expanded(
          child: KeyedSubtree(
            key: _listKey,
            child: widget.leads.isEmpty
                ? _emptyState(col)
                : ListView.builder(
                    controller: _listCtrl,
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.leads.length,
                    itemBuilder: (_, i) {
                      final lead = widget.leads[i];
                      return KanbanLeadCard(
                        // Keyed by id so the entrance animation plays once and a
                        // moved card keeps its identity across rebuilds.
                        key: ValueKey(lead.id),
                        lead: lead,
                        allStatuses: widget.allStatuses,
                        currentStatusId: widget.status.id,
                        accent: col,
                        dragEnabled: widget.dragEnabled,
                        onStatusChange: (newId) =>
                            widget.onStatusChange(lead.id, newId, widget.status.id),
                        onDragStateChanged: widget.onDragStateChanged,
                        onTap: () => widget.onLeadTap(lead.id),
                        onChatTap: () => widget.onChatTap(lead),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(Color col) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 32, color: col.withValues(alpha: 0.3)),
            const SizedBox(height: 6),
            Text(
              'Bo\'sh',
              style: TextStyle(fontSize: 12, color: col.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
