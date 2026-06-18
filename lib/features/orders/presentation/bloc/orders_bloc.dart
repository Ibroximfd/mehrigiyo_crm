import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../domain/entities/order_entity.dart';

abstract class OrdersEvent {
  const OrdersEvent();
}

class LoadOrders extends OrdersEvent {
  final String? status;
  final String? search;
  const LoadOrders({this.status, this.search});
}

abstract class OrdersState {
  const OrdersState();
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
}

class OrdersLoaded extends OrdersState {
  final List<OrderEntity> orders;
  final bool isRefreshing;

  const OrdersLoaded({required this.orders, this.isRefreshing = false});
}

@injectable
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRemoteDataSource dataSource;

  OrdersBloc(this.dataSource) : super(const OrdersInitial()) {
    on<LoadOrders>(_onLoad);
  }

  Future<void> _onLoad(LoadOrders event, Emitter<OrdersState> emit) async {
    emit(const OrdersLoading());
    try {
      final orders = await dataSource.getOrders(
        status: event.status,
        search: event.search,
      );
      emit(OrdersLoaded(orders: orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }
}
