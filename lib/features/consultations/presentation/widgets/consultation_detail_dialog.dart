import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/consultation_entity.dart';
import '../bloc/consultation_action_bloc.dart';
import '../bloc/consultation_action_event.dart';
import '../bloc/consultation_action_state.dart';
import '../../../../core/notifications/badge_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/di_setup.dart';
import 'status_badge.dart';

class ConsultationDetailDialog extends StatefulWidget {
  final ConsultationEntity consultation;
  final VoidCallback onActionSuccess;

  const ConsultationDetailDialog({
    super.key,
    required this.consultation,
    required this.onActionSuccess,
  });

  @override
  State<ConsultationDetailDialog> createState() =>
      _ConsultationDetailDialogState();
}

class _ConsultationDetailDialogState extends State<ConsultationDetailDialog> {
  late TextEditingController _noteController;
  late ConsultationEntity _consultation;
  bool _noteChanged = false;

  @override
  void initState() {
    super.initState();
    _consultation = widget.consultation;
    _noteController = TextEditingController(
      text: widget.consultation.operatorNote ?? '',
    );
    _noteController.addListener(() {
      final changed =
          _noteController.text != (_consultation.operatorNote ?? '');
      if (changed != _noteChanged) setState(() => _noteChanged = changed);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConsultationActionBloc>(
      create: (_) => getIt<ConsultationActionBloc>(),
      child: Dialog(
        child: BlocConsumer<ConsultationActionBloc, ConsultationActionState>(
          listener: (context, state) {
            if (state is ConsultationActionSuccess) {
              if (_consultation.status == 1 && state.updated.status != 1) {
                context.read<BadgeBloc>().add(const DecrementConsultations());
              }
              setState(() {
                _consultation = state.updated;
                _noteController.text = state.updated.operatorNote ?? '';
                _noteChanged = false;
              });
              widget.onActionSuccess();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state is ConsultationActionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is ConsultationActionLoading;

            return Container(
              width: 640,
              constraints: const BoxConstraints(maxHeight: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ariza №${_consultation.id}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(status: _consultation.status),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Mijoz ismi:',
                            value: _consultation.clientName,
                            isPrimary: true,
                          ),
                          const Divider(height: 20),
                          _InfoRow(
                            label: 'Telefon:',
                            value: _consultation.phone,
                          ),
                          const Divider(height: 20),
                          _InfoRow(
                            label: 'Murojaat vaqti:',
                            value: DateFormat(
                              'dd.MM.yyyy HH:mm',
                            ).format(_consultation.createdAt),
                          ),
                          if (_consultation.updatedAt != null) ...[
                            const Divider(height: 20),
                            _InfoRow(
                              label: 'Yangilangan:',
                              value: DateFormat(
                                'dd.MM.yyyy HH:mm',
                              ).format(_consultation.updatedAt!),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Problem
                    const _SectionLabel(text: 'Muammo / Savol'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        _consultation.issueDescription,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Operator note
                    Row(
                      children: [
                        const _SectionLabel(text: 'Operator izohi'),
                        const SizedBox(width: 8),
                        if (_noteChanged)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'o\'zgardi',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Text(
                            'Yopish',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_noteChanged) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Izohni Saqlash'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.read<ConsultationActionBloc>().add(
                                      UpdateConsultationNoteEvent(
                                        id: _consultation.id,
                                        note: _noteController.text.trim(),
                                      ),
                                    );
                                  },
                          ),
                        ],
                        const SizedBox(width: 8),
                        if (_consultation.status < 3)
                          ElevatedButton.icon(
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _consultation.status == 1
                                  ? 'Qabul Qilish'
                                  : 'Tugallash',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _consultation.status == 1
                                  ? AppColors.primary
                                  : AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.read<ConsultationActionBloc>().add(
                                      ChangeConsultationStatusEvent(
                                        _consultation.id,
                                      ),
                                    );
                                  },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: isPrimary ? 15 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
