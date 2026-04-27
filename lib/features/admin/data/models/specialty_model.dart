import '../../domain/entities/specialty_entity.dart';

/// Model de especialidade médica - DTO para serialização.
/// Estende SpecialtyEntity e adiciona métodos fromJson/toJson.
class SpecialtyModel extends SpecialtyEntity {
  const SpecialtyModel({
    required super.id,
    required super.name,
    required super.isActive,
  });

  /// Cria SpecialtyModel a partir de JSON
  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
    };
  }

  /// Cria SpecialtyModel a partir de SpecialtyEntity
  factory SpecialtyModel.fromEntity(SpecialtyEntity entity) {
    return SpecialtyModel(
      id: entity.id,
      name: entity.name,
      isActive: entity.isActive,
    );
  }
}
