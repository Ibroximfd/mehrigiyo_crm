import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/statistics_bloc.dart';
import '../widgets/period_selector.dart';
import '../widgets/stat_card.dart';
import '../widgets/leads_by_status_chart.dart';
import '../widgets/ranking_card.dart';
import '../../domain/entities/statistics_entity.dart';

class AdminStatisticsPage extends StatelessWidget {
  const AdminStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<AdminStatisticsBloc, AdminStatisticsState>(
        builder: (context, state) {
          final period = switch (state) {
            AdminStatisticsLoaded s => s.period,
            AdminStatisticsLoading s => s.period,
            AdminStatisticsError s => s.period,
            _ => 'all',
          };

          return RefreshIndicator(
            color: const Color(0xFF0D6A55),
            onRefresh: () async => context
                .read<AdminStatisticsBloc>()
                .add(const AdminStatisticsLoadRequested()),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistika',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Filial umumiy ko\'rsatkichlari',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        PeriodSelector(
                          selected: period,
                          onChanged: (p) => context
                              .read<AdminStatisticsBloc>()
                              .add(AdminStatisticsPeriodChanged(p)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state is AdminStatisticsLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0D6A55)),
                    ),
                  )
                else if (state is AdminStatisticsError)
                  SliverFillRemaining(
                    child: _ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<AdminStatisticsBloc>()
                          .add(const AdminStatisticsLoadRequested()),
                    ),
                  )
                else if (state is AdminStatisticsLoaded)
                  _AdminStatsContent(state: state)
                else
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminStatsContent extends StatelessWidget {
  final AdminStatisticsLoaded state;
  const _AdminStatsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _SectionTitle('Umumiy'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.people_outline_rounded,
                  iconColor: const Color(0xFF0D6A55),
                  bgColor: const Color(0xFFE6F4F0),
                  label: 'Operatorlar',
                  value: '${state.stats.operatorsCount} ta',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.attach_money_rounded,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  label: 'Jami sotuv',
                  value: _formatMoney(state.stats.totalSales),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Komissiya'),
          const SizedBox(height: 10),
          _AdminCommissionCards(commission: state.stats.commission),
          const SizedBox(height: 20),
          _SectionTitle('Leadlar'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF5F3FF),
                  label: 'Jami lead',
                  value: '${state.stats.leads.total}',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          if (state.stats.leads.byStatus.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle('Leadlar holati bo\'yicha'),
            const SizedBox(height: 10),
            LeadsByStatusChart(byStatus: state.stats.leads.byStatus),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle('Reyting'),
              Text(
                'Jami: ${state.ranking.count} ta',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...state.ranking.results.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final op = entry.value;
            return RankingCard(
              rank: rank,
              operator: op,
              onTap: () => _showOperatorStats(context, op.operatorId, op.fullName, state),
            );
          }),
          if (state.ranking.hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => context
                      .read<AdminStatisticsBloc>()
                      .add(const AdminStatisticsRankingLoadMore()),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text("Ko'proq yuklash"),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  void _showOperatorStats(
    BuildContext context,
    int operatorId,
    String operatorName,
    AdminStatisticsLoaded state,
  ) {
    context
        .read<AdminStatisticsBloc>()
        .add(AdminOperatorStatsRequested(
          operatorId: operatorId,
          operatorName: operatorName,
        ));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminStatisticsBloc>(),
        child: _OperatorStatsSheet(operatorName: operatorName),
      ),
    );
  }
}

class _OperatorStatsSheet extends StatelessWidget {
  final String operatorName;
  const _OperatorStatsSheet({required this.operatorName});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operatorName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Text(
                          'Operator statistikasi',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<AdminStatisticsBloc, AdminStatisticsState>(
                builder: (context, state) {
                  if (state is AdminStatisticsLoaded) {
                    if (state.isLoadingOperatorStats) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0D6A55)),
                      );
                    }
                    final opStats = state.selectedOperatorStats;
                    if (opStats == null) {
                      return const Center(
                        child: Text(
                          'Ma\'lumot topilmadi',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      );
                    }
                    return _OperatorStatsBody(
                      data: opStats,
                      scrollController: scrollController,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatorStatsBody extends StatelessWidget {
  final SellerStatisticsEntity data;
  final ScrollController scrollController;

  const _OperatorStatsBody({
    required this.data,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SectionTitle('Sotuvlar'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF0D6A55),
                bgColor: const Color(0xFFE6F4F0),
                label: 'Sotilgan mahsulot',
                value: '${data.sales.productsSold} ta',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.attach_money_rounded,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                label: 'Jami sotuv',
                value: _formatMoney(data.sales.totalSales),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('Komissiya'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                label: 'Hisoblangan',
                value: _formatMoney(data.commission.totalPaid),
                subtitle: '${data.commission.countPaid} ta',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                label: "To'lab berilgan",
                value: _formatMoney(data.commission.totalTransferred),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('Leadlar'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.people_outline_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                label: 'Jami lead',
                value: '${data.leads.total}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                label: 'Konversiya',
                value: '${data.leads.conversion.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        if (data.leads.byStatus.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Leadlar holati'),
          const SizedBox(height: 10),
          LeadsByStatusChart(byStatus: data.leads.byStatus),
        ],
      ],
    );
  }
}

class _AdminCommissionCards extends StatelessWidget {
  final AdminCommissionEntity commission;
  const _AdminCommissionCards({required this.commission});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
            label: 'Hisoblangan',
            value: _formatMoney(commission.totalPaid),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.hourglass_empty_rounded,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            label: 'Kutilmoqda',
            value: _formatMoney(commission.totalPending),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            label: "To'lab berilgan",
            value: _formatMoney(commission.totalTransferred),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
        letterSpacing: -0.2,
      ),
    );
  }
}

String _formatMoney(double amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)} mln';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)} ming';
  return amount.toStringAsFixed(0);
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Qayta yuklash'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
