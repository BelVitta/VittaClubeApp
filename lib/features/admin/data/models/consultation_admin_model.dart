import '../../domain/entities/consultation_admin_entity.dart';

/// Model de consulta admin - DTO para serialização.
/// Estende ConsultationAdminEntity e adiciona métodos fromJson/toJson.
class ConsultationAdminModel extends ConsultationAdminEntity {
  const ConsultationAdminModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.date,
    required super.professionalId,
    required super.professionalName,
    required super.userId,
    required super.userName,
  });

  /// Cria ConsultationAdminModel a partir de JSON
  factory ConsultationAdminModel.fromJson(Map<String, dynamic> json) {
    return ConsultationAdminModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      date: DateTime.parse(json['date'] as String),
      professionalId: json['professionalId'] as String,
      professionalName: json['professionalName'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'date': date.toIso8601String(),
      'professionalId': professionalId,
      'professionalName': professionalName,
      'userId': userId,
      'userName': userName,
    };
  }

  /// Cria ConsultationAdminModel a partir de ConsultationAdminEntity
  factory ConsultationAdminModel.fromEntity(ConsultationAdminEntity entity) {
    return ConsultationAdminModel(
      id: entity.id,
      title: entity.title,
      subtitle: entity.subtitle,
      date: entity.date,
      professionalId: entity.professionalId,
      professionalName: entity.professionalName,
      userId: entity.userId,
      userName: entity.userName,
    );
  }
}
