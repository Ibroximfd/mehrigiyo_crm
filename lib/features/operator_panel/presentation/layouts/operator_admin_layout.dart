import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/notifications/badge_bloc.dart';
import '../widgets/op_animated_sidebar.dart';

class OperatorAdminLayout extends StatelessWidget {
  final Widget child;
  const OperatorAdminLayout({super.key, required this.child});

  static const _routes = [
    RouteNames.adminOperators,
    RouteNames.adminLeads,
    RouteNames.adminStatuses,
    RouteNames.adminConsultations,
    RouteNames.adminStatistics,
  ];

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(RouteNames.adminLeads)) return 1;
    if (path.startsWith(RouteNames.adminStatuses)) return 2;
    if (path.startsWith(RouteNames.adminConsultations)) return 3;
    if (path.startsWith(RouteNames.adminStatistics)) return 4;
    return 0;
  }

  void _navigate(int index, BuildContext context) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return _MobileAdminLayout(
        selectedIndex: idx,
        onNavigate: (i) => _navigate(i, context),
        child: child,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          BlocBuilder<BadgeBloc, BadgeState>(
            builder: (_, badge) => OpAnimatedSidebar(
              isAdmin: true,
              selectedIndex: idx,
              onItemTap: (i) => _navigate(i, context),
              onLogout: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
              items: [
                const OpNavItem(
                  icon: Icons.people_outline_rounded,
                  selectedIcon: Icons.people_rounded,
                  label: 'Operatorlar',
                ),
                const OpNavItem(
                  icon: Icons.assignment_outlined,
                  selectedIcon: Icons.assignment_rounded,
                  label: 'Leadlar',
                ),
                const OpNavItem(
                  icon: Icons.view_kanban_outlined,
                  selectedIcon: Icons.view_kanban_rounded,
                  label: 'Statuslar',
                ),
                OpNavItem(
                  icon: Icons.mail_outline_rounded,
                  selectedIcon: Icons.mail_rounded,
                  label: 'Arizalar',
                  badgeCount: badge.newConsultations,
                ),
                const OpNavItem(
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart_rounded,
                  label: 'Statistika',
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileAdminLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final Widget child;

  const _MobileAdminLayout({
    required this.selectedIndex,
    required this.onNavigate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.sidebarDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Mehrigiyo CRM',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [_MobileProfileBtn()],
      ),
      body: child,
      bottomNavigationBar: BlocBuilder<BadgeBloc, BadgeState>(
        builder: (_, badge) => NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onNavigate,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Operatorlar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Leadlar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.view_kanban_outlined),
              selectedIcon: Icon(Icons.view_kanban_rounded),
              label: 'Statuslar',
            ),
            NavigationDestination(
              icon: badge.newConsultations > 0
                  ? Badge(
                      label: Text('${badge.newConsultations}'),
                      child: const Icon(Icons.mail_outline_rounded),
                    )
                  : const Icon(Icons.mail_outline_rounded),
              selectedIcon: const Icon(Icons.mail_rounded),
              label: 'Arizalar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Statistika',
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileProfileBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated ? state.user.name : 'A';
        final letter = name.isNotEmpty ? name[0].toUpperCase() : 'A';
        return GestureDetector(
          onTap: () => _showProfileSheet(context, state),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.gold.withValues(alpha: 0.25),
              child: Text(
                letter,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfileSheet(BuildContext context, AuthState state) {
    final name = state is AuthAuthenticated ? state.user.name : 'Admin';
    final filial = state is AuthAuthenticated ? state.user.filialName : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.gold.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (filial != null) ...[
              const SizedBox(height: 4),
              Text(filial,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Chiqish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<AuthBloc>().add(LogoutRequested());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
