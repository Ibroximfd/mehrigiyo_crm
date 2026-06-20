part of 'leads_bloc.dart';

abstract class LeadsEvent extends Equatable {
  const LeadsEvent();
  @override
  List<Object?> get props => [];
}

class LeadsLoadRequested extends LeadsEvent {
  final int? statusId;
  final String? category;
  const LeadsLoadRequested({this.statusId, this.category});
  @override
  List<Object?> get props => [statusId, category];
}

class LeadsLoadMore extends LeadsEvent {
  const LeadsLoadMore();
}

class LeadCreateRequested extends LeadsEvent {
  final String fullName;
  final String phone;
  final String source;
  final String? region;
  final String? note;
  final int? statusId;

  const LeadCreateRequested({
    required this.fullName,
    required this.phone,
    this.source = 'manual',
    this.region,
    this.note,
    this.statusId,
  });

  @override
  List<Object?> get props => [fullName, phone, source, region, note, statusId];
}
