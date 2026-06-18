import 'package:flutter_bloc/flutter_bloc.dart';

sealed class SidebarEvent {
  const SidebarEvent();
}

class SidebarToggled extends SidebarEvent {
  const SidebarToggled();
}

class SidebarState {
  final bool isExpanded;
  const SidebarState({this.isExpanded = false});
}

class SidebarBloc extends Bloc<SidebarEvent, SidebarState> {
  SidebarBloc() : super(const SidebarState()) {
    on<SidebarToggled>((event, emit) {
      emit(SidebarState(isExpanded: !state.isExpanded));
    });
  }
}
