import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String token;
  final String? phone;
  final String? role;

  const UserEntity({
    required this.id,
    required this.name,
    required this.token,
    this.phone,
    this.role,
  });

  @override
  List<Object?> get props => [id, name, token, phone, role];
}
