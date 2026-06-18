import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/notifications/badge_bloc.dart';
import '../../../core/theme/app_colors.dart';
import 'icon_rail_item.dart';

class CrmIconRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  const CrmIconRail({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarDark, AppColors.sidebarMid],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x25000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/web_logo.jpg',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.gold.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<BadgeBloc, BadgeState>(
            builder: (_, badge) => Column(
              children: [
                IconRailItem(
                  icon: Icons.dashboard_rounded,
                  tooltip: 'Boshqaruv Paneli',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTap(0),
                ),
                const SizedBox(height: 8),
                IconRailItem(
                  icon: Icons.assignment_rounded,
                  tooltip: 'Arizalar',
                  isSelected: selectedIndex == 1,
                  badgeCount: badge.newConsultations,
                  onTap: () => onItemTap(1),
                ),
              ],
            ),
          ),
          const Spacer(),
          Tooltip(
            message: 'Chiqish',
            child: GestureDetector(
              onTap: onLogout,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade300,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
