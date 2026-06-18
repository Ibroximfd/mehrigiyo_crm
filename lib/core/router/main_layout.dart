import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../core/notifications/badge_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import 'bloc/sidebar_bloc.dart';
import 'route_names.dart';
import 'widgets/crm_animated_sidebar.dart';
import 'widgets/crm_drawer.dart';
import 'widgets/notification_badge.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(RouteNames.consultations)) return 1;
    return 0;
  }

  void _navigate(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RouteNames.dashboard);
      case 1:
        context.go(RouteNames.consultations);
    }
  }

  void _showProfileDialog(BuildContext context, AuthAuthenticated state) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  state.user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Faol',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (state.user.phone != null &&
                    state.user.phone!.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.phone_rounded,
                    label: 'Telefon',
                    value: state.user.phone!,
                  ),
                  const Divider(height: 20),
                ],
                _InfoRow(
                  icon: Icons.badge_rounded,
                  label: 'Lavozim',
                  value: state.user.role?.isNotEmpty == true
                      ? state.user.role!
                      : 'Operator',
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Yopish'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Chiqish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.read<AuthBloc>().add(LogoutRequested());
                          context.go(RouteNames.login);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex(context);
    final isPhone = Responsive.isPhone(context);

    if (isPhone) {
      return Scaffold(
        backgroundColor: AppColors.background,
        drawer: CrmDrawer(
          selectedIndex: index,
          onItemTap: (i) {
            Navigator.of(context).pop();
            _navigate(i, context);
          },
          onLogout: () {
            Navigator.of(context).pop();
            context.read<AuthBloc>().add(LogoutRequested());
            context.go(RouteNames.login);
          },
          onProfileTap: (state) {
            Navigator.of(context).pop();
            _showProfileDialog(context, state);
          },
        ),
        appBar: AppBar(
          backgroundColor: AppColors.sidebarDark,
          foregroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 56,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/web_logo.jpg',
                  height: 28,
                  width: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Mehrigiyo CRM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BlocBuilder<BadgeBloc, BadgeState>(
            builder: (_, badge) => BottomNavigationBar(
              currentIndex: index,
              onTap: (i) => _navigate(i, context),
              backgroundColor: AppColors.sidebarDark,
              selectedItemColor: AppColors.gold,
              unselectedItemColor: Colors.white.withValues(alpha: 0.5),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Boshqaruv',
                ),
                BottomNavigationBarItem(
                  icon: _BottomNavIcon(
                    icon: Icons.assignment_rounded,
                    badgeCount: badge.newConsultations,
                  ),
                  label: 'Arizalar',
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tablet + Desktop — collapsible animated sidebar
    return BlocProvider(
      create: (_) => SidebarBloc(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            CrmAnimatedSidebar(
              selectedIndex: index,
              onItemTap: (i) => _navigate(i, context),
              onLogout: () {
                context.read<AuthBloc>().add(LogoutRequested());
                context.go(RouteNames.login);
              },
              onProfileTap: (state) => _showProfileDialog(context, state),
            ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final int badgeCount;

  const _BottomNavIcon({required this.icon, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (badgeCount > 0)
          Positioned(
            right: -8,
            top: -6,
            child: NotificationBadge(count: badgeCount),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
