import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/consultations/presentation/pages/consultations_page.dart';
import 'main_layout.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

Page<void> _fadePage(BuildContext ctx, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
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
      final exitFade = Tween<double>(begin: 1.0, end: 0.6).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
        ),
        child: FadeTransition(
          opacity: exitFade,
          child: ScaleTransition(scale: scaleAnim, child: child),
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouteNames.login,
  routes: [
    GoRoute(
      path: RouteNames.login,
      pageBuilder: (ctx, state) => _fadePage(ctx, state, const LoginPage()),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: RouteNames.dashboard,
          pageBuilder: (ctx, state) =>
              _pageTransition(ctx, state, const DashboardPage()),
        ),
        GoRoute(
          path: RouteNames.consultations,
          pageBuilder: (ctx, state) =>
              _pageTransition(ctx, state, const ConsultationsPage()),
        ),
      ],
    ),
  ],
);
