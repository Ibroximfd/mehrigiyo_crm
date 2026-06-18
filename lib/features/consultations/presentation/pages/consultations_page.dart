import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../bloc/consultations_bloc.dart';
import '../bloc/consultations_event.dart';
import '../bloc/consultations_state.dart';
import '../widgets/consultations_filter_panel.dart';
import '../widgets/desktop_consultations_table.dart';
import '../widgets/mobile_consultation_card.dart';
import '../widgets/consultation_detail_dialog.dart';
import '../../domain/entities/consultation_entity.dart';

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  int? _selectedStatus;
  String _searchQuery = '';
  Timer? _searchDebounce;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      final state = context.read<ConsultationsBloc>().state;
      if (state is ConsultationsLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<ConsultationsBloc>().add(const LoadMoreConsultations());
      }
    }
  }

  void _load({bool refresh = false}) {
    context.read<ConsultationsBloc>().add(
      LoadConsultations(
        status: _selectedStatus,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        isRefresh: refresh,
      ),
    );
  }

  void _onStatusChanged(int? status) {
    setState(() => _selectedStatus = status);
    _load();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      _load,
    );
  }

  void _openDetail(ConsultationEntity item) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConsultationDetailDialog(
        consultation: item,
        onActionSuccess: () => _load(refresh: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(
            isPhone: isPhone,
            onRefresh: () => _load(refresh: true),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 16 : 24,
                vertical: 0,
              ),
              child: Column(
                children: [
                  ConsultationsFilterPanel(
                    currentStatus: _selectedStatus,
                    onStatusChanged: _onStatusChanged,
                    onSearchChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: BlocBuilder<ConsultationsBloc, ConsultationsState>(
                      builder: (context, state) {
                        if (state is ConsultationsLoading &&
                            state.oldConsultations.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        if (state is ConsultationsError) {
                          return _ErrorView(
                            message: state.message,
                            onRetry: _load,
                          );
                        }

                        final items = switch (state) {
                          ConsultationsLoaded() => state.consultations,
                          ConsultationsLoading() => state.oldConsultations,
                          _ => <ConsultationEntity>[],
                        };

                        final isRefreshing = state is ConsultationsLoading &&
                            state.oldConsultations.isNotEmpty;

                        final isLoadingMore = state is ConsultationsLoaded &&
                            state.isLoadingMore;

                        if (isPhone) {
                          return _MobileList(
                            items: items,
                            isRefreshing: isRefreshing,
                            isLoadingMore: isLoadingMore,
                            scrollController: _scrollController,
                            onTap: _openDetail,
                          );
                        }

                        return DesktopConsultationsTable(
                          items: items,
                          isRefreshing: isRefreshing,
                          isLoadingMore: isLoadingMore,
                          scrollController: _scrollController,
                          onTap: _openDetail,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool isPhone;
  final VoidCallback onRefresh;

  const _PageHeader({required this.isPhone, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isPhone ? 16 : 24,
        isPhone ? 16 : 24,
        isPhone ? 16 : 24,
        16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arizalar',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                BlocBuilder<ConsultationsBloc, ConsultationsState>(
                  buildWhen: (prev, curr) =>
                      curr is ConsultationsLoaded ||
                      (prev is ConsultationsLoaded && curr is ConsultationsLoading),
                  builder: (context, state) {
                    if (state is ConsultationsLoaded) {
                      return Text(
                        'Jami: ${state.consultations.length} ta'
                        '${state.hasMore ? '+' : ''}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
            ),
            tooltip: 'Yangilash',
          ),
        ],
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  final List<ConsultationEntity> items;
  final bool isRefreshing;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final ValueChanged<ConsultationEntity> onTap;

  const _MobileList({
    required this.items,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.scrollController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
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
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final totalItems = items.length + (isLoadingMore ? 1 : 0);

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => context.read<ConsultationsBloc>().add(
            const LoadConsultations(isRefresh: true),
          ),
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: totalItems,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
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
              return MobileConsultationCard(
                item: items[index],
                onTap: () => onTap(items[index]),
              );
            },
          ),
        ),
        if (isRefreshing)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Xatolik: $message',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Qayta urinish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
