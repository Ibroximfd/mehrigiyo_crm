import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_status_form_event.dart';
part 'create_status_form_state.dart';

/// Holds the transient UI state of the "create status" form.
/// Kept separate from [StatusesBloc] so the form is fully bloc-driven and the
/// dialog can be a [StatelessWidget].
class CreateStatusFormBloc
    extends Bloc<CreateStatusFormEvent, CreateStatusFormState> {
  CreateStatusFormBloc() : super(const CreateStatusFormState()) {
    on<FormNameChanged>((e, emit) => emit(state.copyWith(name: e.name)));
    on<FormCategoryChanged>(
      (e, emit) => emit(state.copyWith(category: e.category)),
    );
    on<FormColorChanged>(_onColorChanged);
    on<FormDefaultToggled>(
      (e, emit) => emit(state.copyWith(isDefault: e.isDefault)),
    );
    on<FormSubmitPressed>((e, emit) => emit(state.copyWith(submitted: true)));
  }

  void _onColorChanged(
    FormColorChanged event,
    Emitter<CreateStatusFormState> emit,
  ) {
    final color = event.color.toUpperCase();
    // Append custom (non-preset) colors so the chosen swatch stays visible.
    final custom = List<String>.from(state.customColors);
    if (!CreateStatusFormState.presetColors.contains(color) &&
        !custom.contains(color)) {
      custom.add(color);
    }
    emit(state.copyWith(color: color, customColors: custom));
  }
}
