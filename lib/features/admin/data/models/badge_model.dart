import '../../domain/entities/badge_entity.dart';

/// Model de badge/emblema de nível - DTO para serialização.
/// Estende BadgeEntity e adiciona métodos fromJson/toJson.
class BadgeModel extends BadgeEntity {
  const BadgeModel({
    required super.id,
    required super.levelName,
    required super.displayName,
    required super.badgeImageUrl,
    required super.progressColor,
    required super.progressBgColor,
    required super.sortOrder,
    super.discountPercentage,
    super.maxConsultationsPerMonth,
  });

  /// Cria BadgeModel a partir de JSON
  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      levelName: json['levelName'] as String,
      displayName: json['displayName'] as String,
      badgeImageUrl: json['badgeImageUrl'] as String,
      progressColor: json['progressColor'] as int,
      progressBgColor: json['progressBgColor'] as int,
      sortOrder: json['sortOrder'] as int,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      maxConsultationsPerMonth: json['maxConsultationsPerMonth'] as int? ?? 0,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'levelName': levelName,
      'displayName': displayName,
      'badgeImageUrl': badgeImageUrl,
      'progressColor': progressColor,
      'progressBgColor': progressBgColor,
      'sortOrder': sortOrder,
      'discountPercentage': discountPercentage,
      'maxConsultationsPerMonth': maxConsultationsPerMonth,
    };
  }

  /// Cria BadgeModel a partir de BadgeEntity
  factory BadgeModel.fromEntity(BadgeEntity entity) {
    return BadgeModel(
      id: entity.id,
      levelName: entity.levelName,
      displayName: entity.displayName,
      badgeImageUrl: entity.badgeImageUrl,
      progressColor: entity.progressColor,
      progressBgColor: entity.progressBgColor,
      sortOrder: entity.sortOrder,
      discountPercentage: entity.discountPercentage,
      maxConsultationsPerMonth: entity.maxConsultationsPerMonth,
    );
  }
}
