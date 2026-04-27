import 'package:equatable/equatable.dart';

/// Entidade de usuário - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String cpf;
  final String phone;
  final String role;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.phone,
    this.role = 'user',
  });

  @override
  List<Object?> get props => [id, name, email, cpf, phone, role];
}
