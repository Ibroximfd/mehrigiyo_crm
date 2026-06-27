import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/money_format.dart';
import '../bloc/statistics_bloc.dart';
import '../widgets/period_selector.dart';
import '../widgets/stat_card.dart';
import '../widgets/leads_by_status_chart.dart';
import '../widgets/order_pipeline_card.dart';
import '../../domain/entities/statistics_entity.dart';

class SellerStatisticsPage extends StatelessWidget {
  const SellerStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<SellerStatisticsBloc, SellerStatisticsState>(
        builder: (context, state) {
          final period = switch (state) {
            SellerStatisticsLoaded s => s.period,
            SellerStatisticsLoading s => s.period,
            SellerStatisticsError s => s.period,
            _ => 'today',
          };

          return RefreshIndicator(
            color: const Color(0xFF0D6A55),
            onRefresh: () async => context
                .read<SellerStatisticsBloc>()
                .add(const SellerStatisticsLoadRequested()),
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
                          'Mening statistikam',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sotuv va komissiya natijalari',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        PeriodSelector(
                          selected: period,
                          onChanged: (p) => context
                              .read<SellerStatisticsBloc>()
                              .add(SellerStatisticsPeriodChanged(p)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state is SellerStatisticsLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0D6A55)),
                    ),
                  )
                else if (state is SellerStatisticsError)
                  SliverFillRemaining(
                    child: _ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<SellerStatisticsBloc>()
                          .add(const SellerStatisticsLoadRequested()),
                    ),
                  )
                else if (state is SellerStatisticsLoaded)
                  _SellerStatsContent(data: state.data)
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

class _SellerStatsContent extends StatelessWidget {
  final SellerStatisticsEntity data;
  const _SellerStatsContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = data.commission;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (data.operator != null) ...[
            _OperatorHero(
              operator: data.operator!,
              // Hero shows order-level total (jarayondagini ham qo'shadi),
              // fall back to item-level sotuv summasi.
              amount: data.orderPipeline?.totalAmount ?? data.sales.totalSales,
              label: data.orderPipeline != null ? 'Jami buyurtma' : 'Jami sotuv',
            ),
            const SizedBox(height: 22),
          ],
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
            const SizedBox(height: 22),
            _SectionTitle('Buyurtmalar'),
            const SizedBox(height: 10),
            OrderPipelineCard(pipeline: data.orderPipeline!),
          ],
          const SizedBox(height: 22),
          _SectionTitle('Komissiya'),
          const SizedBox(height: 10),
          _CommissionCards(commission: c),
          const SizedBox(height: 22),
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
            const SizedBox(height: 22),
            _SectionTitle('Leadlar holati bo\'yicha'),
            const SizedBox(height: 10),
            LeadsByStatusChart(byStatus: data.leads.byStatus),
          ],
        ]),
      ),
    );
  }
}

class _OperatorHero extends StatelessWidget {
  final OperatorInfoEntity operator;
  final double amount;
  final String label;
  const _OperatorHero({
    required this.operator,
    required this.amount,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        operator.fullName.isNotEmpty ? operator.fullName[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D6A55), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6A55).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operator.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${operator.username}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatSom(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
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

class _CommissionCards extends StatelessWidget {
  final CommissionStatsEntity commission;
  const _CommissionCards({required this.commission});

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
