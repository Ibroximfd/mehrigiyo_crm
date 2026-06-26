import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/di_setup.dart';
import 'core/notifications/badge_bloc.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/consultations/presentation/bloc/consultations_bloc.dart';
import 'features/orders/data/datasources/order_remote_data_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MehrigiyoCrmApp());
}

class MehrigiyoCrmApp extends StatelessWidget {
  const MehrigiyoCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => getIt<DashboardBloc>()),
        BlocProvider(create: (_) => getIt<ConsultationsBloc>()),
        BlocProvider(
          create: (_) => BadgeBloc(
            dashboardDataSource: getIt<DashboardRemoteDataSource>(),
            ordersDataSource: getIt<OrderRemoteDataSource>(),
          ),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Route based on operator role
            if (state.user.isAdmin) {
              appRouter.go(RouteNames.adminLeads);
            } else {
              appRouter.go(RouteNames.sellerKanban);
            }
          } else if (state is AuthUnauthenticated || state is AuthError) {
            context.read<BadgeBloc>().add(const ResetBadgeCounts());
            appRouter.go(RouteNames.login);
          }
        },
        child: MaterialApp.router(
          title: 'Mehrigiyo CRM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
