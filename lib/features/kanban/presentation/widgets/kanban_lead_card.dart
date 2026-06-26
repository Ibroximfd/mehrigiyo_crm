import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bitrix_call_button.dart';
import '../../../leads/domain/entities/lead_entity.dart';
import '../../../statuses/domain/entities/status_entity.dart';
import '../../../statuses/presentation/widgets/status_picker_dialog.dart';
import 'lead_drag_feedback_widget.dart';

class KanbanLeadCard extends StatefulWidget {
  final LeadEntity lead;
  final List<StatusEntity> allStatuses;

  /// Id of the column this card currently lives in (drag source).
  final int currentStatusId;

  /// Accent color of the owning column (used for the drag feedback border).
  final Color accent;

  /// When true the card can be dragged between columns (web only).
  final bool dragEnabled;

  final void Function(int newStatusId) onStatusChange;

  /// Notifies the board that a drag started ([data] != null) or ended (null),
  /// so every valid target column can highlight itself.
  final void Function(LeadDragData? data) onDragStateChanged;

  final VoidCallback? onTap;
  final VoidCallback? onChatTap;

  const KanbanLeadCard({
    super.key,
    required this.lead,
    required this.allStatuses,
    required this.currentStatusId,
    required this.accent,
    required this.dragEnabled,
    required this.onStatusChange,
    required this.onDragStateChanged,
    this.onTap,
    this.onChatTap,
  });

  @override
  State<KanbanLeadCard> createState() => _KanbanLeadCardState();
}

class _KanbanLeadCardState extends State<KanbanLeadCard>
    with TickerProviderStateMixin {
  bool _hovered = false;
  bool _dragging = false;

  // One-shot entrance: slide from top + fade. Plays once per mount, so a card
  // only animates when it first appears in a column (incl. after a move).
  late final AnimationController _entranceCtrl;
  // Pickup feedback: scales the in-place card to 0.95 the moment a drag starts.
  late final AnimationController _pickupCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
    _pickupCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pickupCtrl.dispose();
    super.dispose();
  }

  LeadDragData get _dragData =>
      LeadDragData(leadId: widget.lead.id, fromStatusId: widget.currentStatusId);

  /// Compact dd.MM.yyyy created date, or null if the raw value can't be parsed.
  String? get _createdDate {
    final raw = widget.lead.createdAt;
    if (raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  void _onDragStarted() {
    setState(() => _dragging = true);
    _pickupCtrl.reverse(); // 1.0 -> 0.95
    widget.onDragStateChanged(_dragData);
  }

  void _onDragFinished() {
    if (mounted) setState(() => _dragging = false);
    _pickupCtrl.forward(); // back to 1.0
    widget.onDragStateChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);
    final card = FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.12),
          end: Offset.zero,
        ).animate(entrance),
        child: _buildCard(context),
      ),
    );

    if (!widget.dragEnabled) return card;

    return Draggable<LeadDragData>(
      data: _dragData,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: LeadDragFeedbackWidget(lead: widget.lead, accent: widget.accent),
      childWhenDragging: _placeholder(context),
      onDragStarted: _onDragStarted,
      onDragEnd: (_) => _onDragFinished(),
      onDraggableCanceled: (_, _) => _onDragFinished(),
      onDragCompleted: _onDragFinished,
      child: MouseRegion(
        cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: ScaleTransition(
          scale: _pickupCtrl,
          alignment: Alignment.center,
          child: card,
        ),
      ),
    );
  }

  /// Same footprint as the real card but invisible, with a dashed border drawn
  /// on top — keeps the column from collapsing while the card is in flight.
  Widget _placeholder(BuildContext context) {
    return Stack(
      children: [
        Opacity(opacity: 0, child: _buildCard(context)),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 8,
          child: _DashedSlot(),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return MouseRegion(
      cursor: widget.dragEnabled
          ? SystemMouseCursors.grab
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? AppColors.primary : const Color(0xFFE8ECF0),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.10 : 0.05),
                blurRadius: _hovered ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lead.fullName,
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
                        const Icon(
                          Icons.phone_rounded,
                          size: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(child: _PhoneCopy(phone: widget.lead.phone)),
                      ],
                    ),
                    if (widget.lead.region != null &&
                        widget.lead.region!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.lead.region!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.lead.assignedTo != null) ...[
                      const SizedBox(height: 3),
                      _MetaRow(
                        icon: Icons.person_rounded,
                        text: widget.lead.assignedTo!.fullName,
                      ),
                    ],
                    if (_createdDate != null) ...[
                      const SizedBox(height: 3),
                      _MetaRow(
                        icon: Icons.calendar_today_rounded,
                        text: _createdDate!,
                      ),
                    ],
                  ],
                ),
              ),

              // Action row
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                  border: Border(top: BorderSide(color: Color(0xFFEFF2F5))),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFD1FAE5),
                      tooltip: 'Chat ochish',
                      onTap: widget.onChatTap,
                    ),
                    const SizedBox(width: 8),
                    BitrixCallButton(phone: widget.lead.phone, size: 36),
                    const Spacer(),
                    _ActionBtn(
                      icon: Icons.swap_horiz_rounded,
                      color: AppColors.primary,
                      bgColor: AppColors.primaryLight,
                      tooltip: 'Ko\'chirish',
                      onTap: () => _showMoveMenu(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveMenu(BuildContext context) {
    showStatusPickerDialog(
      context: context,
      leadName: widget.lead.fullName,
      currentStatusId: widget.lead.statusId,
      statuses: widget.allStatuses,
      onSelected: widget.onStatusChange,
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DashedSlot extends StatelessWidget {
  const _DashedSlot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: AppColors.primary.withValues(alpha: 0.5),
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

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(14),
      ));
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final next = d + dash;
        canvas.drawPath(
          metric.extractPath(d, next.clamp(0, metric.length)),
          paint,
        );
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _PhoneCopy extends StatelessWidget {
  final String phone;
  const _PhoneCopy({required this.phone});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            phone,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.copy_rounded, size: 12, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
