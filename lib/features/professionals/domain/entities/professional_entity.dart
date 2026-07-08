import 'package:equatable/equatable.dart';

/// Profissional ativo exibido na listagem pública (tabela `professionals`).
class ProfessionalEntity extends Equatable {
  final String id;
  final String name;
  final String specialtyName;
  final String availableDays;
  final String? avatarUrl;
  final int avatarBgColor;

  const ProfessionalEntity({
    required this.id,
    required this.name,
    required this.specialtyName,
    required this.availableDays,
    this.avatarUrl,
    required this.avatarBgColor,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        specialtyName,
        availableDays,
        avatarUrl,
        avatarBgColor,
      ];
}
