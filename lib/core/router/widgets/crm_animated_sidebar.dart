import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/notifications/badge_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../bloc/sidebar_bloc.dart';
import '../route_names.dart';
import 'notification_badge.dart';

const double _kCollapsed = 64.0;
const double _kExpanded = 240.0;

class CrmAnimatedSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;
  final void Function(AuthAuthenticated) onProfileTap;

  const CrmAnimatedSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
    required this.onProfileTap,
  });

  @override
  State<CrmAnimatedSidebar> createState() => _CrmAnimatedSidebarState();
}

class _CrmAnimatedSidebarState extends State<CrmAnimatedSidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _syncAnimation(SidebarState state) {
    if (state.isExpanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SidebarBloc, SidebarState>(
      listener: (_, state) => _syncAnimation(state),
      child: AnimatedBuilder(
        animation: _expandAnim,
        builder: (context, _) {
          final w = _kCollapsed + (_kExpanded - _kCollapsed) * _expandAnim.value;
          return SizedBox(
            width: w,
            child: _SidebarBody(
              expandValue: _expandAnim.value,
              selectedIndex: widget.selectedIndex,
              onItemTap: widget.onItemTap,
              onLogout: widget.onLogout,
              onProfileTap: widget.onProfileTap,
            ),
          );
        },
      ),
    );
  }
}

class _SidebarBody extends StatelessWidget {
  final double expandValue;
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;
  final void Function(AuthAuthenticated) onProfileTap;

  const _SidebarBody({
    required this.expandValue,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarDark, AppColors.sidebarMid],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 24,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _ToggleButton(expandValue: expandValue),
          const SizedBox(height: 12),
          _LogoSection(expandValue: expandValue),
          const SizedBox(height: 10),
          _GoldDivider(),
          const SizedBox(height: 10),
          BlocBuilder<BadgeBloc, BadgeState>(
            builder: (_, badge) => Column(
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Boshqaruv',
                  isSelected: selectedIndex == 0,
                  expandValue: expandValue,
                  badgeCount: 0,
                  onTap: () => onItemTap(0),
                ),
                _NavItem(
                  icon: Icons.assignment_rounded,
                  label: 'Arizalar',
                  isSelected: selectedIndex == 1,
                  expandValue: expandValue,
                  badgeCount: badge.newConsultations,
                  onTap: () => onItemTap(1),
                ),
              ],
            ),
          ),
          const Spacer(),
          _GoldDivider(),
          const SizedBox(height: 8),
          _UserSection(
            expandValue: expandValue,
            onLogout: onLogout,
            onProfileTap: onProfileTap,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final double expandValue;
  const _ToggleButton({required this.expandValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Align(
        alignment: expandValue > 0.5
            ? Alignment.centerRight
            : Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(
            right: expandValue > 0.5 ? 8 : 0,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () =>
                  context.read<SidebarBloc>().add(const SidebarToggled()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  expandValue > 0.5
                      ? Icons.chevron_left_rounded
                      : Icons.menu_rounded,
                  color: Colors.white.withValues(alpha: 0.75),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  final double expandValue;
  const _LogoSection({required this.expandValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go(RouteNames.dashboard),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/web_logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: expandValue,
              child: Opacity(
                opacity: expandValue,
                child: const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mehrigiyo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'CRM tizimi',
                        style: TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final double expandValue;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.expandValue,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? AppColors.gold
        : Colors.white.withValues(alpha: 0.68);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.gold.withValues(alpha: 0.16)
                  : _hovered
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.gold.withValues(alpha: 0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon area — 40px (border 1.5×2=3px eats into the 44px container)
                SizedBox(
                  width: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(widget.icon, color: color, size: 20),
                      if (widget.badgeCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: NotificationBadge(count: widget.badgeCount),
                        ),
                    ],
                  ),
                ),
                // Label — animates in/out
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.expandValue,
                    child: Opacity(
                      opacity: widget.expandValue,
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: color,
                        ),
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  final double expandValue;
  final VoidCallback onLogout;
  final void Function(AuthAuthenticated) onProfileTap;

  const _UserSection({
    required this.expandValue,
    required this.onLogout,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onTap: () {
              if (state is AuthAuthenticated) onProfileTap(state);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar — 34px fits within the 36px inner slot (44 - pad6 - border2)
                    SizedBox(
                      width: 34,
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    // Name + logout — fixed-width box so Row stays bounded
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: expandValue,
                        child: Opacity(
                          opacity: expandValue,
                          child: SizedBox(
                            width: _kExpanded - _kCollapsed,
                            child: Row(
                              children: [
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    user?.name ?? 'Operator',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red.shade300,
                                    size: 17,
                                  ),
                                  tooltip: 'Chiqish',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: onLogout,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
