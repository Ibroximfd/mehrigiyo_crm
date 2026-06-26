import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/di_setup.dart';
import '../../../operator_chat/domain/usecases/chat_usecases.dart';
import '../../../operator_order/presentation/bloc/operator_order_bloc.dart';
import '../../../operator_order/presentation/widgets/create_operator_order_dialog.dart';
import '../bloc/lead_detail_bloc.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/usecases/lead_usecases.dart';
import '../../../statuses/domain/usecases/status_usecases.dart';
import '../../../statuses/presentation/widgets/status_picker_dialog.dart';

class LeadDetailPage extends StatelessWidget {
  final int leadId;
  const LeadDetailPage({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeadDetailBloc(
        getDetail: getIt<GetLeadDetailUseCase>(),
        changeStatus: getIt<ChangeLeadStatusUseCase>(),
        getHistory: getIt<GetLeadHistoryUseCase>(),
        getStatuses: getIt<GetStatusesUseCase>(),
      )..add(LeadDetailLoadRequested(leadId)),
      child: _LeadDetailView(leadId: leadId),
    );
  }
}

class _LeadDetailView extends StatelessWidget {
  final int leadId;
  const _LeadDetailView({required this.leadId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mijoz ma\'lumotlari'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: Color(0xFF1E293B),
        actions: [
          BlocBuilder<LeadDetailBloc, LeadDetailState>(
            builder: (ctx, state) {
              final lead = state is LeadDetailLoaded
                  ? state.lead
                  : state is LeadDetailChangingStatus
                  ? state.lead
                  : null;
              if (lead != null) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded),
                      tooltip: 'Chat ochish',
                      onPressed: () => _openChat(ctx, lead),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      tooltip: 'Buyurtma yaratish',
                      onPressed: () => _showCreateOrderDialog(ctx, lead),
                    ),
                    if (state is LeadDetailLoaded)
                      IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded),
                        tooltip: 'Status o\'zgartirish',
                        onPressed: () => _showStatusSheet(ctx, state),
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<LeadDetailBloc, LeadDetailState>(
        listenWhen: (_, s) => s is LeadDetailLoaded && s.statusError != null,
        listener: (ctx, state) {
          if (state is LeadDetailLoaded && state.statusError != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.statusError!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (ctx, state) {
          if (state is LeadDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is LeadDetailError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ctx.read<LeadDetailBloc>().add(
                      LeadDetailLoadRequested(leadId),
                    ),
                    child: const Text('Qayta yuklash'),
                  ),
                ],
              ),
            );
          }

          final lead = state is LeadDetailLoaded
              ? state.lead
              : state is LeadDetailChangingStatus
              ? state.lead
              : null;
          final history = state is LeadDetailLoaded
              ? state.history
              : state is LeadDetailChangingStatus
              ? state.history
              : <LeadStatusHistory>[];
          final changingStatus = state is LeadDetailChangingStatus;

          if (lead == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LeadInfoCard(lead: lead),
                const SizedBox(height: 12),
                if (changingStatus)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Status o\'zgartirilmoqda...',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                _HistoryCard(history: history),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openChat(BuildContext context, LeadEntity lead) async {
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
    Navigator.of(context, rootNavigator: true).pop();
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
      ),
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

  void _showCreateOrderDialog(BuildContext context, LeadEntity lead) {
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<OperatorOrderBloc>()),
          RepositoryProvider.value(value: getIt<SearchProductsUseCase>()),
        ],
        child: CreateOperatorOrderDialog(phone: lead.phone, leadId: lead.id),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, LeadDetailLoaded state) {
    showStatusPickerDialog(
      context: context,
      leadName: state.lead.fullName,
      currentStatusId: state.lead.statusId,
      statuses: state.statuses,
      onSelected: (statusId) => context.read<LeadDetailBloc>().add(
        LeadStatusChangeRequested(statusId),
      ),
    );
  }
}

class _LeadInfoCard extends StatelessWidget {
  final LeadEntity lead;
  const _LeadInfoCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  lead.fullName.isNotEmpty
                      ? lead.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: lead.phone),
                        );
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
                            lead.phone,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (lead.region != null && lead.region!.isNotEmpty)
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Hudud',
              value: lead.region!,
            ),
          if (lead.assignedTo != null)
            _InfoRow(
              icon: Icons.person_rounded,
              label: 'Sotuvchi',
              value: lead.assignedTo!.fullName,
            ),
          _InfoRow(
            icon: Icons.source_rounded,
            label: 'Manba',
            value: _sourceLabel(lead.source),
          ),
          if (lead.note != null && lead.note!.isNotEmpty)
            _InfoRow(
              icon: Icons.notes_rounded,
              label: 'Izoh',
              value: lead.note!,
              maxLines: 4,
            ),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Qo\'shilgan',
            value: _formatDate(lead.createdAt),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(String source) {
    const map = {
      'manual': 'Qo\'lda',
      'app': 'Ilova',
      'instagram': 'Instagram',
      'facebook': 'Facebook',
      'bitrix': 'Bitrix',
    };
    return map[source] ?? source;
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<LeadStatusHistory> history;
  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Holat tarixi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...history.map((h) => _HistoryItem(item: h)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final LeadStatusHistory item;
  const _HistoryItem({required this.item});

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.fromStatusName != null) ...[
                      Text(
                        item.fromStatusName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_right_alt_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        item.toStatusName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_formatDate(item.createdAt)}${item.changedByName != null ? ' · ${item.changedByName}' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
