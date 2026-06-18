// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i107;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/consultations/data/datasources/consultation_remote_data_source.dart'
    as _i1012;
import '../../features/consultations/data/repositories/consultation_repository_impl.dart'
    as _i865;
import '../../features/consultations/domain/repositories/consultation_repository.dart'
    as _i769;
import '../../features/consultations/domain/usecases/consultation_usecases.dart'
    as _i25;
import '../../features/consultations/presentation/bloc/consultation_action_bloc.dart'
    as _i175;
import '../../features/consultations/presentation/bloc/consultations_bloc.dart'
    as _i30;
import '../../features/dashboard/data/datasources/dashboard_remote_data_source.dart'
    as _i258;
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart'
    as _i509;
import '../../features/dashboard/domain/repositories/dashboard_repository.dart'
    as _i665;
import '../../features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart'
    as _i765;
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart'
    as _i652;
import '../../features/orders/data/datasources/order_remote_data_source.dart'
    as _i1011;
import '../../features/orders/presentation/bloc/orders_bloc.dart' as _i349;
import '../network/api_client.dart' as _i557;
import '../network/dio_interceptor.dart' as _i32;
import 'di_setup.dart' as _i125;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.factory<_i32.DioInterceptor>(
      () => _i32.DioInterceptor(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i557.ApiClient>(
      () => _i557.ApiClient(gh<_i361.Dio>(), gh<_i32.DioInterceptor>()),
    );
    gh.lazySingleton<_i107.AuthRemoteDataSource>(
      () => _i107.AuthRemoteDataSourceImpl(gh<_i557.ApiClient>()),
    );
    gh.lazySingleton<_i1011.OrderRemoteDataSource>(
      () => _i1011.OrderRemoteDataSourceImpl(gh<_i557.ApiClient>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(
        remoteDataSource: gh<_i107.AuthRemoteDataSource>(),
        prefs: gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i258.DashboardRemoteDataSource>(
      () => _i258.DashboardRemoteDataSourceImpl(gh<_i557.ApiClient>()),
    );
    gh.lazySingleton<_i188.LoginUseCase>(
      () => _i188.LoginUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i1012.ConsultationRemoteDataSource>(
      () => _i1012.ConsultationRemoteDataSourceImpl(gh<_i557.ApiClient>()),
    );
    gh.factory<_i349.OrdersBloc>(
      () => _i349.OrdersBloc(gh<_i1011.OrderRemoteDataSource>()),
    );
    gh.lazySingleton<_i769.ConsultationRepository>(
      () => _i865.ConsultationRepositoryImpl(
        remoteDataSource: gh<_i1012.ConsultationRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i665.DashboardRepository>(
      () => _i509.DashboardRepositoryImpl(
        remoteDataSource: gh<_i258.DashboardRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i765.GetDashboardStatsUseCase>(
      () => _i765.GetDashboardStatsUseCase(gh<_i665.DashboardRepository>()),
    );
    gh.factory<_i797.AuthBloc>(
      () => _i797.AuthBloc(
        loginUseCase: gh<_i188.LoginUseCase>(),
        repository: gh<_i787.AuthRepository>(),
      ),
    );
    gh.lazySingleton<_i25.GetConsultationsUseCase>(
      () => _i25.GetConsultationsUseCase(gh<_i769.ConsultationRepository>()),
    );
    gh.lazySingleton<_i25.GetConsultationDetailUseCase>(
      () =>
          _i25.GetConsultationDetailUseCase(gh<_i769.ConsultationRepository>()),
    );
    gh.lazySingleton<_i25.ChangeStatusUseCase>(
      () => _i25.ChangeStatusUseCase(gh<_i769.ConsultationRepository>()),
    );
    gh.lazySingleton<_i25.UpdateNoteUseCase>(
      () => _i25.UpdateNoteUseCase(gh<_i769.ConsultationRepository>()),
    );
    gh.factory<_i30.ConsultationsBloc>(
      () => _i30.ConsultationsBloc(
        getConsultationsUseCase: gh<_i25.GetConsultationsUseCase>(),
      ),
    );
    gh.factory<_i652.DashboardBloc>(
      () => _i652.DashboardBloc(
        getStatsUseCase: gh<_i765.GetDashboardStatsUseCase>(),
      ),
    );
    gh.factory<_i175.ConsultationActionBloc>(
      () => _i175.ConsultationActionBloc(
        changeStatusUseCase: gh<_i25.ChangeStatusUseCase>(),
        updateNoteUseCase: gh<_i25.UpdateNoteUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i125.RegisterModule {}
