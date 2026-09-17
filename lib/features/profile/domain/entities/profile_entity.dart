import 'package:equatable/equatable.dart';

/// Perfil público do usuário logado (tabela `profiles`).
class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final DateTime memberSince;

  /// Código curto de 8 dígitos para digitação na recepção (não é o UUID).
  final String? memberCode;

  /// Código que a recepcionista passa no balcão (só role `admin`).
  final String? receptionistCode;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.memberSince,
    this.memberCode,
    this.receptionistCode,
  });

  /// Primeiro nome para uso em saudações ("Olá, Diana").
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// `financeiro` é o "super admin" — tem tudo que `admin` tem, e mais.
  bool get hasAdminAccess => role == 'admin' || role == 'financeiro';

  /// Código formatado para UI: `8472-9103`.
  String get memberCodeDisplay {
    final raw = (memberCode ?? '').replaceAll(RegExp(r'\D'), '');
    if (raw.length != 8) {
      return memberCode?.isNotEmpty == true ? memberCode! : '—';
    }
    return '${raw.substring(0, 4)}-${raw.substring(4)}';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatarUrl,
        role,
        memberSince,
        memberCode,
        receptionistCode
      ];
}
