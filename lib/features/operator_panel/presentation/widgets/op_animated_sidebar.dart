import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';

const double _kCollapsed = 64.0;
const double _kExpanded = 240.0;

class OpNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;

  const OpNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class OpAnimatedSidebar extends StatefulWidget {
  final List<OpNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;
  final bool isAdmin;

  const OpAnimatedSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
    this.isAdmin = false,
  });

  @override
  State<OpAnimatedSidebar> createState() => _OpAnimatedSidebarState();
}

class _OpAnimatedSidebarState extends State<OpAnimatedSidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
    _anim = CurvedAnimation(
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

  void _toggle() {
    if (_expanded) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final w = _kCollapsed + (_kExpanded - _kCollapsed) * _anim.value;
        return SizedBox(
          width: w,
          child: _SidebarBody(
            expandValue: _anim.value,
            items: widget.items,
            selectedIndex: widget.selectedIndex,
            onItemTap: widget.onItemTap,
            onToggle: _toggle,
            onLogout: widget.onLogout,
            isAdmin: widget.isAdmin,
          ),
        );
      },
    );
  }
}

class _SidebarBody extends StatelessWidget {
  final double expandValue;
  final List<OpNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onToggle;
  final VoidCallback onLogout;
  final bool isAdmin;

  const _SidebarBody({
    required this.expandValue,
    required this.items,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onToggle,
    required this.onLogout,
    required this.isAdmin,
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
            color: Color(0x28000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _ToggleRow(expandValue: expandValue, onToggle: onToggle),
          const SizedBox(height: 12),
          _LogoRow(expandValue: expandValue, isAdmin: isAdmin),
          const SizedBox(height: 12),
          _Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (_, i) => _NavItem(
                item: items[i],
                isSelected: selectedIndex == i,
                expandValue: expandValue,
                onTap: () => onItemTap(i),
              ),
            ),
          ),
          _Divider(),
          const SizedBox(height: 8),
          _UserRow(
            expandValue: expandValue,
            onLogout: onLogout,
            isAdmin: isAdmin,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final double expandValue;
  final VoidCallback onToggle;
  const _ToggleRow({required this.expandValue, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Align(
        alignment: expandValue > 0.5 ? Alignment.centerRight : Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(right: expandValue > 0.5 ? 8 : 0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  expandValue > 0.5
                      ? Icons.chevron_left_rounded
                      : Icons.menu_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
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

class _LogoRow extends StatelessWidget {
  final double expandValue;
  final bool isAdmin;
  const _LogoRow({required this.expandValue, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdmin
                    ? [AppColors.gold, AppColors.gold.withValues(alpha: 0.7)]
                    : [AppColors.accent, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings_rounded : Icons.storefront_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: expandValue,
              child: Opacity(
                opacity: expandValue,
                child: SizedBox(
                  width: _kExpanded - _kCollapsed,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Mehrigiyo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          isAdmin ? 'Admin panel' : 'Sotuvchi panel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
    );
  }
}

class _NavItem extends StatefulWidget {
  final OpNavItem item;
  final bool isSelected;
  final double expandValue;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.expandValue,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.accent;
    final isSelected = widget.isSelected;
    final color = isSelected ? accentColor : Colors.white.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.14)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon zone — fixed 44px wide
                SizedBox(
                  width: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? widget.item.selectedIcon : widget.item.icon,
                        color: color,
                        size: 20,
                      ),
                      if (widget.item.badgeCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: _Badge(count: widget.item.badgeCount),
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
                      child: SizedBox(
                        width: _kExpanded - _kCollapsed,
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFEF4444),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final double expandValue;
  final VoidCallback onLogout;
  final bool isAdmin;

  const _UserRow({
    required this.expandValue,
    required this.onLogout,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final name = user?.name ?? '';
        final avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final avatarColor = isAdmin ? AppColors.gold : AppColors.accent;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            avatarLetter,
                            style: TextStyle(
                              color: avatarColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
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
                        child: SizedBox(
                          width: _kExpanded - _kCollapsed,
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty ? 'Operator' : name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      isAdmin ? 'Admin' : 'Sotuvchi',
                                      style: TextStyle(
                                        color: avatarColor.withValues(alpha: 0.8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.logout_rounded,
                                  color: Colors.red.shade300,
                                  size: 16,
                                ),
                                tooltip: 'Chiqish',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
        );
      },
    );
  }
}
