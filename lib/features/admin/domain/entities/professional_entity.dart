import 'package:equatable/equatable.dart';

/// Entidade de profissional no painel admin - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class ProfessionalEntity extends Equatable {
  final String id;
  final String name;
  final String specialtyId;
  final String specialtyName;
  final String availableDays;
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
        avatarUrl,
        avatarBgColor,
        whatsappNumber,
        isActive,
      ];
}
