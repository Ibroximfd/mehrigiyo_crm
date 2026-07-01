part of 'create_status_form_bloc.dart';

class CreateStatusFormState extends Equatable {
  final String name;
  final String category;
  final String color; // '#RRGGBB'
  final bool isDefault;
  final List<String> customColors;
  final bool submitted;

  const CreateStatusFormState({
    this.name = '',
    this.category = 'sales',
    this.color = '#6B7280',
    this.isDefault = false,
    this.customColors = const [],
    this.submitted = false,
  });

  static const List<String> presetColors = [
    '#6B7280', '#0D6A55', '#1AAB87', '#F59E0B',
    '#DC3545', '#3B82F6', '#8B5CF6', '#EC4899',
  ];

  /// Preset + user-picked colors, in display order.
  List<String> get swatches => [...presetColors, ...customColors];

  bool get isNameValid => name.trim().isNotEmpty;

  /// Inline error shown only after a submit attempt.
  String? get nameError =>
      submitted && !isNameValid ? 'Nom kiritilishi shart' : null;

  CreateStatusFormState copyWith({
    String? name,
    String? category,
    String? color,
    bool? isDefault,
    List<String>? customColors,
    bool? submitted,
  }) {
    return CreateStatusFormState(
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      customColors: customColors ?? this.customColors,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props =>
      [name, category, color, isDefault, customColors, submitted];
}
