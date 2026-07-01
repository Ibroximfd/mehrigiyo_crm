part of 'create_status_form_bloc.dart';

abstract class CreateStatusFormEvent extends Equatable {
  const CreateStatusFormEvent();

  @override
  List<Object?> get props => [];
}

class FormNameChanged extends CreateStatusFormEvent {
  final String name;
  const FormNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class FormCategoryChanged extends CreateStatusFormEvent {
  final String category;
  const FormCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class FormColorChanged extends CreateStatusFormEvent {
  final String color; // '#RRGGBB'
  const FormColorChanged(this.color);

  @override
  List<Object?> get props => [color];
}

class FormDefaultToggled extends CreateStatusFormEvent {
  final bool isDefault;
  const FormDefaultToggled(this.isDefault);

  @override
  List<Object?> get props => [isDefault];
}

/// Marks that the user pressed submit at least once, enabling inline validation.
class FormSubmitPressed extends CreateStatusFormEvent {
  const FormSubmitPressed();
}
