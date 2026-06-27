import 'package:flutter/material.dart';
import '../../../../core/utils/money_format.dart';
import '../../domain/entities/statistics_entity.dart';

class RankingCard extends StatelessWidget {
  final OperatorRankingEntity operator;
  final int rank;
  final VoidCallback? onTap;

  const RankingCard({
    super.key,
    required this.operator,
    required this.rank,
    this.onTap,
  });

  bool get _isTop => rank <= 3;

  @override
  Widget build(BuildContext context) {
    final initial =
        operator.fullName.isNotEmpty ? operator.fullName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isTop
                ? const Color(0xFF0D6A55).withValues(alpha: 0.18)
                : const Color(0xFFEEF2F6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  _RankBadge(rank: rank),
                  const SizedBox(width: 12),
                  _Avatar(initial: initial, isTop: _isTop),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operator.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${operator.username}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatSom(operator.totalSales),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D6A55),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Sotuv',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1), size: 20),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _Metric(
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF2563EB),
                    label: 'Komissiya',
                    value: formatSom(operator.totalCommissionPaid),
                  ),
                  _MetricDivider(),
                  _Metric(
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0D6A55),
                    label: 'Mahsulot',
                    value: '${operator.productsSold} ta',
                  ),
                  _MetricDivider(),
                  _Metric(
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFF16A34A),
                    label: 'Yetkazildi',
                    value: '${operator.ordersDelivered} ta',
                  ),
                  _MetricDivider(),
                  _Metric(
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF7C3AED),
                    label: 'Lead',
                    value: '${operator.totalLeads} ta',
                  ),
                  _MetricDivider(),
                  _Metric(
                    icon: Icons.trending_up_rounded,
                    color: operator.conversion >= 20
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF94A3B8),
                    label: 'Konversiya',
                    value: '${trimZero(operator.conversion)}%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final bool isTop;
  const _Avatar({required this.initial, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isTop ? const Color(0xFFE6F4F0) : const Color(0xFFF1F5F9),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: isTop ? const Color(0xFF0D6A55) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFF1F5F9),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      const medals = ['🥇', '🥈', '🥉'];
      return SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Text(medals[rank - 1], style: const TextStyle(fontSize: 22)),
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
