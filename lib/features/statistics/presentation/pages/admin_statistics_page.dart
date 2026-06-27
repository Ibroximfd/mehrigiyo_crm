import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/money_format.dart';
import '../bloc/statistics_bloc.dart';
import '../widgets/period_selector.dart';
import '../widgets/stat_card.dart';
import '../widgets/leads_by_status_chart.dart';
import '../widgets/order_pipeline_card.dart';
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
    final stats = state.stats;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _AdminHero(
            filialName: stats.filial?.name ?? '',
            // Hero shows order-level total (jarayondagini ham qo'shadi),
            // fall back to item-level sotuv summasi.
            amount: stats.orderPipeline?.totalAmount ?? stats.totalSales,
            amountLabel:
                stats.orderPipeline != null ? 'Jami buyurtma' : 'Jami sotuv',
            operatorsCount: stats.operatorsCount,
            commissionPaid: stats.commission.earned,
            totalLeads: stats.leads.total,
          ),
          const SizedBox(height: 22),
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
                  value: '${stats.productsSold} ta',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  label: 'Jami sotuv',
                  value: formatSom(stats.totalSales),
                ),
              ),
            ],
          ),
          if (stats.orderPipeline != null) ...[
            const SizedBox(height: 22),
            _SectionTitle('Buyurtmalar'),
            const SizedBox(height: 10),
            OrderPipelineCard(pipeline: stats.orderPipeline!),
          ],
          const SizedBox(height: 22),
          _SectionTitle('Komissiya'),
          const SizedBox(height: 10),
          _AdminCommissionCards(commission: stats.commission),
          const SizedBox(height: 22),
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
                  value: '${stats.leads.total} ta',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.repeat_rounded,
                  iconColor: const Color(0xFF0891B2),
                  bgColor: const Color(0xFFECFEFF),
                  label: 'Sotuvdan keyingi',
                  value: '${stats.leads.postSaleLeads} ta',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ConversionCard(percent: stats.leads.conversion),
          if (stats.leads.byStatus.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionTitle('Leadlar holati bo\'yicha'),
            const SizedBox(height: 10),
            LeadsByStatusChart(byStatus: stats.leads.byStatus),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle('Operatorlar reytingi'),
              Text(
                'Jami: ${state.ranking.count} ta',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                label: 'Jami sotuv',
                value: formatSom(data.sales.totalSales),
              ),
            ),
          ],
        ),
        if (data.orderPipeline != null) ...[
          const SizedBox(height: 16),
          _SectionTitle('Buyurtmalar'),
          const SizedBox(height: 10),
          OrderPipelineCard(pipeline: data.orderPipeline!),
        ],
        const SizedBox(height: 16),
        _SectionTitle('Komissiya'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.savings_outlined,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                label: 'Jami topilgan',
                value: formatSom(data.commission.earned),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.hourglass_empty_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                label: 'Kutilmoqda',
                value: formatSom(data.commission.pendingPayout),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: StatCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            label: "To'lab berilgan",
            value: formatSom(data.commission.transferred),
          ),
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
                value: '${data.leads.total} ta',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.repeat_rounded,
                iconColor: const Color(0xFF0891B2),
                bgColor: const Color(0xFFECFEFF),
                label: 'Sotuvdan keyingi',
                value: '${data.leads.postSaleLeads} ta',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ConversionCard(percent: data.leads.conversion),
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
  final CommissionStatsEntity commission;
  const _AdminCommissionCards({required this.commission});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.savings_outlined,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                label: 'Jami topilgan',
                value: formatSom(commission.earned),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.hourglass_empty_rounded,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                label: 'Kutilmoqda',
                value: formatSom(commission.pendingPayout),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: StatCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            label: "To'lab berilgan",
            value: formatSom(commission.transferred),
          ),
        ),
      ],
    );
  }
}

class _AdminHero extends StatelessWidget {
  final String filialName;
  final double amount;
  final String amountLabel;
  final int operatorsCount;
  final double commissionPaid;
  final int totalLeads;

  const _AdminHero({
    required this.filialName,
    required this.amount,
    required this.amountLabel,
    required this.operatorsCount,
    required this.commissionPaid,
    required this.totalLeads,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D6A55), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6A55).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.store_mall_directory_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filialName.isNotEmpty ? filialName : 'Filial',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      amountLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatSom(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _HeroMetric(
                  icon: Icons.people_alt_outlined,
                  label: 'Operator',
                  value: '$operatorsCount',
                ),
                _HeroSep(),
                _HeroMetric(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Komissiya',
                  value: formatSom(commissionPaid),
                ),
                _HeroSep(),
                _HeroMetric(
                  icon: Icons.people_outline_rounded,
                  label: 'Lead',
                  value: '$totalLeads',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 17),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _ConversionCard extends StatelessWidget {
  final double percent;
  const _ConversionCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    final fraction = (percent / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    size: 20, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konversiya',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ),
              Text(
                '${trimZero(percent)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
            ),
          ),
        ],
      ),
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
