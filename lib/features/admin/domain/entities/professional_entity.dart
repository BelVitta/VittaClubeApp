import 'package:equatable/equatable.dart';

/// Entidade de profissional no painel admin - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class ProfessionalEntity extends Equatable {
  final String id;
  final String name;
  final String specialtyId;
  final String specialtyName;
  final String availableDays;

  /// Observação livre pra disponibilidade que não cabe num conjunto de dias
  /// da semana (ex.: "atende 1x por mês"). Quando preenchida, tem
  /// prioridade sobre [availableDays] na exibição.
  final String? availabilityNote;
  final String avatarUrl;
  final int avatarBgColor;
  final String whatsappNumber;
  final bool isActive;

  const ProfessionalEntity({
    required this.id,
    required this.name,
    required this.specialtyId,
    required this.specialtyName,
    required this.availableDays,
    this.availabilityNote,
    required this.avatarUrl,
    required this.avatarBgColor,
    required this.whatsappNumber,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        specialtyId,
        specialtyName,
        availableDays,
        availabilityNote,
        avatarUrl,
        avatarBgColor,
        whatsappNumber,
        isActive,
      ];
}
