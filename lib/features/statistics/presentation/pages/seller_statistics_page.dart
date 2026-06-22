import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/statistics_bloc.dart';
import '../widgets/period_selector.dart';
import '../widgets/stat_card.dart';
import '../widgets/leads_by_status_chart.dart';
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
            _ => 'all',
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
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
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
          const SizedBox(height: 20),
          _SectionTitle('Komissiya'),
          const SizedBox(height: 10),
          _CommissionCards(commission: data.commission),
          const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            _SectionTitle('Leadlar holati bo\'yicha'),
            const SizedBox(height: 10),
            LeadsByStatusChart(byStatus: data.leads.byStatus),
          ],
        ]),
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
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                label: 'Hisoblangan',
                value: _formatMoney(commission.totalPaid),
                subtitle: '${commission.countPaid} ta',
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
                subtitle: '${commission.countPending} ta',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                label: "To'lab berilgan",
                value: _formatMoney(commission.totalTransferred),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.cancel_outlined,
                iconColor: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEE2E2),
                label: 'Bekor qilingan',
                value: _formatMoney(commission.totalCancelled),
              ),
            ),
          ],
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
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)} mln';
  }
  if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)} ming';
  }
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
