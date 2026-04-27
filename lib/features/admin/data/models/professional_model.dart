import '../../domain/entities/professional_entity.dart';

/// Model de profissional admin - DTO para serialização.
/// Estende ProfessionalEntity e adiciona métodos fromJson/toJson.
class ProfessionalModel extends ProfessionalEntity {
  const ProfessionalModel({
    required super.id,
    required super.name,
    required super.specialtyId,
    required super.specialtyName,
    required super.availableDays,
    required super.avatarUrl,
    required super.avatarBgColor,
    required super.whatsappNumber,
    required super.isActive,
  });

  /// Cria ProfessionalModel a partir de JSON
  factory ProfessionalModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      specialtyId: json['specialtyId'] as String,
      specialtyName: json['specialtyName'] as String,
      availableDays: json['availableDays'] as String,
      avatarUrl: json['avatarUrl'] as String,
      avatarBgColor: json['avatarBgColor'] as int,
      whatsappNumber: json['whatsappNumber'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialtyId': specialtyId,
      'specialtyName': specialtyName,
      'availableDays': availableDays,
      'avatarUrl': avatarUrl,
      'avatarBgColor': avatarBgColor,
      'whatsappNumber': whatsappNumber,
      'isActive': isActive,
    };
  }

  /// Cria ProfessionalModel a partir de ProfessionalEntity
  factory ProfessionalModel.fromEntity(ProfessionalEntity entity) {
    return ProfessionalModel(
      id: entity.id,
      name: entity.name,
      specialtyId: entity.specialtyId,
      specialtyName: entity.specialtyName,
      availableDays: entity.availableDays,
      avatarUrl: entity.avatarUrl,
      avatarBgColor: entity.avatarBgColor,
      whatsappNumber: entity.whatsappNumber,
      isActive: entity.isActive,
    );
  }
}
