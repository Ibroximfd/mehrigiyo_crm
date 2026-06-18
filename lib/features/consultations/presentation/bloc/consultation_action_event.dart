import 'package:equatable/equatable.dart';

abstract class ConsultationActionEvent extends Equatable {
  const ConsultationActionEvent();

  @override
  List<Object?> get props => [];
}

class ChangeConsultationStatusEvent extends ConsultationActionEvent {
  final String id;
  const ChangeConsultationStatusEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateConsultationNoteEvent extends ConsultationActionEvent {
  final String id;
  final String note;
  const UpdateConsultationNoteEvent({required this.id, required this.note});

  @override
  List<Object?> get props => [id, note];
}
