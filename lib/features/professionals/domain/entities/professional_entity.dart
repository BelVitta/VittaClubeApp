import 'package:equatable/equatable.dart';

/// Profissional ativo exibido na listagem pública (tabela `professionals`).
class ProfessionalEntity extends Equatable {
  final String id;
  final String name;
  final String specialtyName;
  final String availableDays;

  /// Observação livre pra disponibilidade que não cabe num conjunto de dias
  /// da semana (ex.: "atende 1x por mês"). Quando preenchida, tem
  /// prioridade sobre [availableDays] na exibição.
  final String? availabilityNote;
  final String? avatarUrl;
  final int avatarBgColor;

  const ProfessionalEntity({
    required this.id,
    required this.name,
    required this.specialtyName,
    required this.availableDays,
    this.availabilityNote,
    this.avatarUrl,
    required this.avatarBgColor,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        specialtyName,
        availableDays,
        availabilityNote,
        avatarUrl,
        avatarBgColor,
      ];
}
