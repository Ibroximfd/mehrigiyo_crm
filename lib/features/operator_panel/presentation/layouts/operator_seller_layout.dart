import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/operator_chat/presentation/bloc/chat_list_bloc.dart';
import '../../../../core/notifications/badge_bloc.dart';
import '../widgets/op_animated_sidebar.dart';

class OperatorSellerLayout extends StatelessWidget {
  final Widget child;
  const OperatorSellerLayout({super.key, required this.child});

  static const _routes = [
    RouteNames.sellerKanban,
    RouteNames.sellerConsultations,
    RouteNames.sellerChat,
    RouteNames.sellerStatistics,
  ];

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(RouteNames.sellerStatistics)) return 3;
    if (path.startsWith(RouteNames.sellerChat)) return 2;
    if (path.startsWith(RouteNames.sellerConsultations)) return 1;
    // Board (kanban) is the default — lead detail pages open from the board too
    return 0;
  }

  bool _isDetailPage(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final segments = path.split('/');
    final isLeadDetail = path.contains('/leads/') && segments.length > 5;
    final isChatRoom = path.contains('/chat/') && segments.length > 5;
    return isLeadDetail || isChatRoom;
  }

  void _navigate(int index, BuildContext context) {
    context.go(_routes[index]);
  }

  /// How many chats currently have unread messages (0 when not yet loaded).
  static int _unreadChats(ChatListState state) =>
      state is ChatListLoaded ? state.unreadRoomCount : 0;

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    final isMobile = Responsive.isMobile(context);
    final isDetail = _isDetailPage(context);

    if (isMobile) {
      return _MobileSellerLayout(
        selectedIndex: idx,
        onNavigate: (i) => _navigate(i, context),
        showBottomNav: !isDetail,
        showAppBar: !isDetail,
        child: child,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          BlocBuilder<BadgeBloc, BadgeState>(
            builder: (_, badge) => BlocBuilder<ChatListBloc, ChatListState>(
              builder: (_, chat) => OpAnimatedSidebar(
                isAdmin: false,
                selectedIndex: idx,
                onItemTap: (i) => _navigate(i, context),
                onLogout: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                },
                items: [
                  const OpNavItem(
                    icon: Icons.view_kanban_outlined,
                    selectedIcon: Icons.view_kanban_rounded,
                    label: 'Board',
                  ),
                  OpNavItem(
                    icon: Icons.mail_outline_rounded,
                    selectedIcon: Icons.mail_rounded,
                    label: 'Arizalar',
                    badgeCount: badge.newConsultations,
                  ),
                  OpNavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    selectedIcon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    badgeCount: _unreadChats(chat),
                  ),
                  const OpNavItem(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart_rounded,
                    label: 'Statistika',
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileSellerLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final bool showBottomNav;
  final bool showAppBar;
  final Widget child;

  const _MobileSellerLayout({
    required this.selectedIndex,
    required this.onNavigate,
    required this.showBottomNav,
    required this.showAppBar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: showAppBar
          ? AppBar(
              backgroundColor: AppColors.sidebarDark,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Mehrigiyo CRM',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              actions: [_MobileProfileBtn()],
            )
          : null,
      body: child,
      bottomNavigationBar: showBottomNav
          ? BlocBuilder<BadgeBloc, BadgeState>(
              builder: (_, badge) => BlocBuilder<ChatListBloc, ChatListState>(
                builder: (_, chat) {
                  final unreadChats = OperatorSellerLayout._unreadChats(chat);
                  return NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onNavigate,
                    backgroundColor: Colors.white,
                    indicatorColor: AppColors.primaryLight,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      const NavigationDestination(
                        icon: Icon(Icons.view_kanban_outlined),
                        selectedIcon: Icon(Icons.view_kanban_rounded),
                        label: 'Board',
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
                      NavigationDestination(
                        icon: unreadChats > 0
                            ? Badge(
                                label: Text('$unreadChats'),
                                child: const Icon(Icons.chat_bubble_outline_rounded),
                              )
                            : const Icon(Icons.chat_bubble_outline_rounded),
                        selectedIcon: const Icon(Icons.chat_bubble_rounded),
                        label: 'Chat',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.bar_chart_outlined),
                        selectedIcon: Icon(Icons.bar_chart_rounded),
                        label: 'Statistika',
                      ),
                    ],
                  );
                },
              ),
            )
          : null,
    );
  }
}

class _MobileProfileBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated ? state.user.name : 'S';
        final letter = name.isNotEmpty ? name[0].toUpperCase() : 'S';
        return GestureDetector(
          onTap: () => _showProfileSheet(context, state),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withValues(alpha: 0.25),
              child: Text(
                letter,
                style: const TextStyle(
                  color: AppColors.accent,
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
    final user = state is AuthAuthenticated ? state.user : null;
    final name = user?.name ?? '';
    final filial = user?.filialName;
    final commission = user?.commissionPercent;

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
              backgroundColor: AppColors.primaryLight,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
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
            if (commission != null) ...[
              const SizedBox(height: 4),
              Text(
                'Komissiya: $commission%',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
