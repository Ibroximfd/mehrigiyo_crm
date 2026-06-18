import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../core/notifications/badge_bloc.dart';
import '../../../core/theme/app_colors.dart';
import 'sidebar_item.dart';

class CrmSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;
  final void Function(AuthAuthenticated state) onProfileTap;

  const CrmSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarDark, AppColors.sidebarMid],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 32,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _LogoSection(),
          const SizedBox(height: 28),
          _Divider(),
          const SizedBox(height: 16),
          _NavItems(
            selectedIndex: selectedIndex,
            onItemTap: onItemTap,
          ),
          const Spacer(),
          _Divider(),
          const SizedBox(height: 12),
          _UserSection(onLogout: onLogout, onProfileTap: onProfileTap),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/web_logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mehrigiyo CRM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Boshqaruv tizimi',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.gold.withValues(alpha: 0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItems extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  const _NavItems({required this.selectedIndex, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BadgeBloc, BadgeState>(
      builder: (_, badge) => Column(
        children: [
          SidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Boshqaruv Paneli',
            isSelected: selectedIndex == 0,
            onTap: () => onItemTap(0),
          ),
          SidebarItem(
            icon: Icons.assignment_rounded,
            label: 'Arizalar',
            isSelected: selectedIndex == 1,
            badgeCount: badge.newConsultations,
            onTap: () => onItemTap(1),
          ),
        ],
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  final VoidCallback onLogout;
  final void Function(AuthAuthenticated state) onProfileTap;

  const _UserSection({required this.onLogout, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final userName = user?.name ?? 'Operator';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (state is AuthAuthenticated) {
                      onProfileTap(state);
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
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
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (state is AuthAuthenticated) {
                        onProfileTap(state);
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Faol',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade300,
                    size: 18,
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
        );
      },
    );
  }
}
