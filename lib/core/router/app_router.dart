import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/consultations/presentation/pages/consultations_page.dart';
import '../../features/operators/presentation/bloc/operators_bloc.dart';
import '../../features/operators/presentation/pages/operators_page.dart';
import '../../features/statuses/presentation/bloc/statuses_bloc.dart';
import '../../features/statuses/presentation/pages/statuses_page.dart';
import '../../features/leads/presentation/bloc/admin_leads_bloc.dart';
import '../../features/leads/presentation/pages/admin_leads_page.dart';
import '../../features/leads/presentation/pages/lead_detail_page.dart';
import '../../features/kanban/presentation/bloc/kanban_bloc.dart';
import '../../features/kanban/presentation/pages/kanban_page.dart';
import '../../features/operator_chat/presentation/bloc/chat_list_bloc.dart';
import '../../features/operator_chat/presentation/bloc/chat_room_bloc.dart';
import '../../features/operator_chat/presentation/pages/chat_list_page.dart';
import '../../features/operator_chat/presentation/pages/chat_room_page.dart';
import '../../features/operator_panel/presentation/layouts/operator_admin_layout.dart';
import '../../features/operator_panel/presentation/layouts/operator_seller_layout.dart';
import '../../features/statistics/presentation/bloc/statistics_bloc.dart';
import '../../features/statistics/presentation/pages/seller_statistics_page.dart';
import '../../features/statistics/presentation/pages/admin_statistics_page.dart';
import '../../core/di/di_setup.dart';
import 'main_layout.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final _adminShellKey = GlobalKey<NavigatorState>(debugLabel: 'admin');
final _sellerShellKey = GlobalKey<NavigatorState>(debugLabel: 'seller');

Page<void> _fadePage(BuildContext ctx, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
  );
}

Page<void> _slidePage(BuildContext ctx, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return SlideTransition(position: slide, child: child);
    },
  );
}

Page<void> _pageTransition(BuildContext ctx, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final scaleAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
        ),
        child: ScaleTransition(scale: scaleAnim, child: child),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouteNames.login,
  routes: [
    // ─── Auth ───────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.login,
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const LoginPage()),
    ),

    // ─── Support (existing) ─────────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: RouteNames.dashboard,
          pageBuilder: (ctx, state) => _pageTransition(ctx, state, const DashboardPage()),
        ),
        GoRoute(
          path: RouteNames.consultations,
          pageBuilder: (ctx, state) => _pageTransition(ctx, state, const ConsultationsPage()),
        ),
      ],
    ),

    // ─── Operator Admin Panel ────────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _adminShellKey,
      builder: (context, state, child) => _AdminShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.adminOperators,
          pageBuilder: (ctx, state) => _pageTransition(
            ctx, state,
            BlocProvider(
              create: (_) => getIt<OperatorsBloc>()..add(const OperatorsLoadRequested()),
              child: const OperatorsPage(),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.adminLeads,
          pageBuilder: (ctx, state) => _pageTransition(
            ctx, state,
            MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => getIt<AdminLeadsBloc>()..add(const AdminLeadsLoadRequested()),
                ),
                BlocProvider(
                  create: (_) => getIt<OperatorsBloc>()..add(const OperatorsLoadRequested()),
                ),
              ],
              child: Builder(
                builder: (ctx) {
                  final opsState = ctx.watch<OperatorsBloc>().state;
                  final operators = opsState is OperatorsLoaded ? opsState.operators : const [];
                  return AdminLeadsPage(operators: List.from(operators));
                },
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.adminStatuses,
          pageBuilder: (ctx, state) => _pageTransition(
            ctx, state,
            BlocProvider(
              create: (_) => getIt<StatusesBloc>()..add(const StatusesLoadRequested()),
              child: const StatusesPage(),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.adminConsultations,
          pageBuilder: (ctx, state) =>
              _pageTransition(ctx, state, const ConsultationsPage()),
        ),
        GoRoute(
          path: RouteNames.adminStatistics,
          pageBuilder: (ctx, state) => _pageTransition(
            ctx, state,
            BlocProvider(
              create: (_) => getIt<AdminStatisticsBloc>()
                ..add(const AdminStatisticsLoadRequested()),
              child: const AdminStatisticsPage(),
            ),
          ),
        ),
      ],
    ),

    // ─── Operator Seller Panel ───────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _sellerShellKey,
      builder: (context, state, child) => _SellerShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.sellerKanban,
          pageBuilder: (ctx, state) => _pageTransition(
            ctx, state,
            BlocProvider(
              create: (_) => getIt<KanbanBloc>()..add(const KanbanLoadRequested()),
              child: const KanbanPage(),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.sellerLeadDetailParam,
          pageBuilder: (ctx, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return _slidePage(ctx, state, LeadDetailPage(leadId: id));
          },
        ),
        GoRoute(
          path: RouteNames.sellerConsultations,
          pageBuilder: (ctx, state) =>
              _pageTransition(ctx, state, const ConsultationsPage()),
        ),
        GoRoute(
          path: RouteNames.sellerChat,
          pageBuilder: (ctx, state) => _pageTransition(
            ctx,
            state,
            BlocProvider(
              create: (_) => getIt<ChatListBloc>()..add(const ChatListLoadRequested()),
              child: const ChatListPage(),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.sellerStatistics,
          pageBuilder: (ctx, state) => _pageTransition(
            ctx, state,
            BlocProvider(
              create: (_) => getIt<SellerStatisticsBloc>()
                ..add(const SellerStatisticsLoadRequested()),
              child: const SellerStatisticsPage(),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.sellerChatRoomParam,
          pageBuilder: (ctx, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            final extra = state.extra as Map<String, dynamic>?;
            final name = extra?['name'] as String?;
            final phone = extra?['phone'] as String?;
            final leadId = extra?['leadId'] as int?;
            return _slidePage(
              ctx,
              state,
              BlocProvider(
                create: (_) => getIt<ChatRoomBloc>(),
                child: ChatRoomPage(
                  roomId: id,
                  participantName: name,
                  participantPhone: phone,
                  leadId: leadId,
                ),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

class _AdminShell extends StatelessWidget {
  final Widget child;
  const _AdminShell({required this.child});

  @override
  Widget build(BuildContext context) => OperatorAdminLayout(child: child);
}

class _SellerShell extends StatelessWidget {
  final Widget child;
  const _SellerShell({required this.child});

  @override
  Widget build(BuildContext context) => OperatorSellerLayout(child: child);
}
