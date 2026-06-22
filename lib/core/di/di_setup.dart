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
import '../websocket/operator_ws_service.dart';
import '../../features/operator_chat/data/datasources/chat_remote_data_source.dart';
import '../../features/operator_chat/data/repositories/chat_repository_impl.dart';
import '../../features/operator_chat/data/services/chat_ws_service.dart';
import '../../features/operator_chat/domain/repositories/chat_repository.dart';
import '../../features/operator_chat/domain/usecases/chat_usecases.dart';
import '../../features/operator_chat/presentation/bloc/chat_list_bloc.dart';
import '../../features/operator_chat/presentation/bloc/chat_room_bloc.dart';
import '../../features/operator_order/data/datasources/operator_order_data_source.dart';
import '../../features/operator_order/data/repositories/operator_order_repository_impl.dart';
import '../../features/operator_order/domain/repositories/operator_order_repository.dart';
import '../../features/operator_order/domain/usecases/operator_order_usecases.dart';
import '../../features/operator_order/presentation/bloc/operator_order_bloc.dart';

import '../../features/statistics/data/datasources/statistics_remote_data_source.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/statistics_usecases.dart';
import '../../features/statistics/presentation/bloc/statistics_bloc.dart';

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
  getIt.registerLazySingleton(() => BulkCreateLeadsUseCase(getIt<LeadRepository>()));

  // ── WebSocket services ─────────────────────────────────────────────────────
  getIt.registerLazySingleton<OperatorWsService>(() => OperatorWsService());

  // ── Chat (seller) ──────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(apiClient),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(getIt<ChatRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => CreateChatRoomUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => GetChatRoomsUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => GetChatMessagesUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => SendChatMessageUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => SendRecommendationUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => SearchProductsUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => HasMoreProductsUseCase(getIt<ChatRepository>()));

  // ── Operator Orders (seller) ───────────────────────────────────────────────
  getIt.registerLazySingleton<OperatorOrderDataSource>(
    () => OperatorOrderDataSourceImpl(apiClient),
  );
  getIt.registerLazySingleton<OperatorOrderRepository>(
    () => OperatorOrderRepositoryImpl(getIt<OperatorOrderDataSource>()),
  );
  getIt.registerLazySingleton(() => CreateManualOrderUseCase(getIt<OperatorOrderRepository>()));
  getIt.registerLazySingleton(() => CreateOrderFromRecommendationUseCase(getIt<OperatorOrderRepository>()));
  getIt.registerFactory(() => OperatorOrderBloc(
    createManual: getIt<CreateManualOrderUseCase>(),
    createFromRecommendation: getIt<CreateOrderFromRecommendationUseCase>(),
  ));

  getIt.registerFactory(() => ChatListBloc(
    getRooms: getIt<GetChatRoomsUseCase>(),
    createRoom: getIt<CreateChatRoomUseCase>(),
  ));
  // ChatRoomBloc: factory so each room gets its own WS instance
  getIt.registerFactory(() => ChatRoomBloc(
    getMessages: getIt<GetChatMessagesUseCase>(),
    sendMessage: getIt<SendChatMessageUseCase>(),
    sendRecommendation: getIt<SendRecommendationUseCase>(),
    searchProducts: getIt<SearchProductsUseCase>(),
    hasMoreProducts: getIt<HasMoreProductsUseCase>(),
    wsService: ChatWsService(),
  ));

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
    bulkCreateLeads: getIt<BulkCreateLeadsUseCase>(),
  ));

  getIt.registerFactory(() => LeadDetailBloc(
    getDetail: getIt<GetLeadDetailUseCase>(),
    changeStatus: getIt<ChangeLeadStatusUseCase>(),
    getHistory: getIt<GetLeadHistoryUseCase>(),
  ));

  // ── Statistics ─────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<StatisticsRemoteDataSource>(
    () => StatisticsRemoteDataSourceImpl(apiClient),
  );
  getIt.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepositoryImpl(getIt<StatisticsRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => GetMyStatisticsUseCase(getIt<StatisticsRepository>()));
  getIt.registerLazySingleton(() => GetAdminStatisticsUseCase(getIt<StatisticsRepository>()));
  getIt.registerLazySingleton(() => GetOperatorsRankingUseCase(getIt<StatisticsRepository>()));
  getIt.registerLazySingleton(() => GetOperatorStatsUseCase(getIt<StatisticsRepository>()));

  getIt.registerFactory(() => SellerStatisticsBloc(
    getMyStats: getIt<GetMyStatisticsUseCase>(),
  ));
  getIt.registerFactory(() => AdminStatisticsBloc(
    getAdminStats: getIt<GetAdminStatisticsUseCase>(),
    getRanking: getIt<GetOperatorsRankingUseCase>(),
    getOperatorStats: getIt<GetOperatorStatsUseCase>(),
  ));

  getIt.registerFactory(() => KanbanBloc(
    getStatuses: getIt<GetStatusesUseCase>(),
    getMyLeads: getIt<GetMyLeadsUseCase>(),
    changeStatus: getIt<ChangeLeadStatusUseCase>(),
    createLead: getIt<CreateLeadUseCase>(),
    wsService: getIt<OperatorWsService>(),
  ));
}

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio();

  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
