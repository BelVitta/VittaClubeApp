import 'package:equatable/equatable.dart';

/// Perfil público do usuário logado (tabela `profiles`).
class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final DateTime memberSince;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.memberSince,
  });

  /// Primeiro nome para uso em saudações ("Olá, Diana").
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  List<Object?> get props => [id, name, email, avatarUrl, role, memberSince];
}
