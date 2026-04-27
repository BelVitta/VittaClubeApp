import '../../domain/entities/user_entity.dart';

/// Model de usuário - DTO para serialização.
/// Estende UserEntity e adiciona métodos fromJson/toJson.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.cpf,
    required super.phone,
    super.role,
  });

  /// Cria UserModel a partir de JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      cpf: json['cpf'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String? ?? 'user',
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'cpf': cpf,
      'phone': phone,
      'role': role,
    };
  }

  /// Cria UserModel a partir de UserEntity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      cpf: entity.cpf,
      phone: entity.phone,
      role: entity.role,
    );
  }
}
