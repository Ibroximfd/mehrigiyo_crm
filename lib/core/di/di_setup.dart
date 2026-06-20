import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'di_setup.config.dart';

// ─── Feature imports ──────────────────────────────────────────────────────────
import '../../features/operators/data/datasources/operator_remote_data_source.dart';
import '../../features/operators/data/repositories/operator_repository_impl.dart';
import '../../features/operators/domain/repositories/operator_repository.dart';
import '../../features/operators/domain/usecases/operator_usecases.dart';
import '../../features/operators/presentation/bloc/operators_bloc.dart';

import '../../features/statuses/data/datasources/status_remote_data_source.dart';
import '../../features/statuses/data/repositories/status_repository_impl.dart';
import '../../features/statuses/domain/repositories/status_repository.dart';
import '../../features/statuses/domain/usecases/status_usecases.dart';
import '../../features/statuses/presentation/bloc/statuses_bloc.dart';

import '../../features/leads/data/datasources/lead_remote_data_source.dart';
import '../../features/leads/data/repositories/lead_repository_impl.dart';
import '../../features/leads/domain/repositories/lead_repository.dart';
import '../../features/leads/domain/usecases/lead_usecases.dart';
import '../../features/leads/presentation/bloc/leads_bloc.dart';
import '../../features/leads/presentation/bloc/admin_leads_bloc.dart';
import '../../features/leads/presentation/bloc/lead_detail_bloc.dart';

import '../../features/kanban/presentation/bloc/kanban_bloc.dart';

import '../network/api_client.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  await getIt.init();
  _registerOperatorFeatures();
}

void _registerOperatorFeatures() {
  final apiClient = getIt<ApiClient>();

  // ── Operator datasources ───────────────────────────────────────────────────
  getIt.registerLazySingleton<OperatorRemoteDataSource>(
    () => OperatorRemoteDataSourceImpl(apiClient),
  );
  getIt.registerLazySingleton<StatusRemoteDataSource>(
    () => StatusRemoteDataSourceImpl(apiClient),
  );
  getIt.registerLazySingleton<LeadRemoteDataSource>(
    () => LeadRemoteDataSourceImpl(apiClient),
  );

  // ── Operator repositories ──────────────────────────────────────────────────
  getIt.registerLazySingleton<OperatorRepository>(
    () => OperatorRepositoryImpl(getIt<OperatorRemoteDataSource>()),
  );
  getIt.registerLazySingleton<StatusRepository>(
    () => StatusRepositoryImpl(getIt<StatusRemoteDataSource>()),
  );
  getIt.registerLazySingleton<LeadRepository>(
    () => LeadRepositoryImpl(getIt<LeadRemoteDataSource>()),
  );

  // ── Operator use cases ─────────────────────────────────────────────────────
  getIt.registerLazySingleton(() => GetOperatorsUseCase(getIt<OperatorRepository>()));
  getIt.registerLazySingleton(() => CreateOperatorUseCase(getIt<OperatorRepository>()));

  getIt.registerLazySingleton(() => GetStatusesUseCase(getIt<StatusRepository>()));
  getIt.registerLazySingleton(() => CreateStatusUseCase(getIt<StatusRepository>()));
  getIt.registerLazySingleton(() => UpdateStatusUseCase(getIt<StatusRepository>()));
  getIt.registerLazySingleton(() => DeleteStatusUseCase(getIt<StatusRepository>()));

  getIt.registerLazySingleton(() => GetMyLeadsUseCase(getIt<LeadRepository>()));
  getIt.registerLazySingleton(() => CreateLeadUseCase(getIt<LeadRepository>()));
  getIt.registerLazySingleton(() => GetLeadDetailUseCase(getIt<LeadRepository>()));
  getIt.registerLazySingleton(() => ChangeLeadStatusUseCase(getIt<LeadRepository>()));
  getIt.registerLazySingleton(() => GetLeadHistoryUseCase(getIt<LeadRepository>()));
  getIt.registerLazySingleton(() => GetAdminLeadsUseCase(getIt<LeadRepository>()));
  getIt.registerLazySingleton(() => AssignLeadsUseCase(getIt<LeadRepository>()));

  // ── Operator BLoCs (factory = new instance each time) ─────────────────────
  getIt.registerFactory(() => OperatorsBloc(
    getOperators: getIt<GetOperatorsUseCase>(),
    createOperator: getIt<CreateOperatorUseCase>(),
  ));

  getIt.registerFactory(() => StatusesBloc(
    getStatuses: getIt<GetStatusesUseCase>(),
    createStatus: getIt<CreateStatusUseCase>(),
    deleteStatus: getIt<DeleteStatusUseCase>(),
  ));

  getIt.registerFactory(() => LeadsBloc(
    getMyLeads: getIt<GetMyLeadsUseCase>(),
    createLead: getIt<CreateLeadUseCase>(),
  ));

  getIt.registerFactory(() => AdminLeadsBloc(
    getAdminLeads: getIt<GetAdminLeadsUseCase>(),
    assignLeads: getIt<AssignLeadsUseCase>(),
  ));

  getIt.registerFactory(() => LeadDetailBloc(
    getDetail: getIt<GetLeadDetailUseCase>(),
    changeStatus: getIt<ChangeLeadStatusUseCase>(),
    getHistory: getIt<GetLeadHistoryUseCase>(),
  ));

  getIt.registerFactory(() => KanbanBloc(
    getStatuses: getIt<GetStatusesUseCase>(),
    getMyLeads: getIt<GetMyLeadsUseCase>(),
    changeStatus: getIt<ChangeLeadStatusUseCase>(),
    createLead: getIt<CreateLeadUseCase>(),
  ));
}

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio();

  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
